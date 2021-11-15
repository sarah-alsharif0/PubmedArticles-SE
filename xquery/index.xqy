xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace adv = "http://marklogic.com/MLU/top-songs/advanced" at "../modules/advanced-lib.xqy";
declare variable $options :=
  <options xmlns="http://marklogic.com/appservices/search">
    <constraint name="Author">
<range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
<element name="LastName"/>
<facet-option>limit=30</facet-option>
<facet-option>frequency-order</facet-option>
<facet-option>descending</facet-option>
</range>
</constraint>
<constraint name="authorLastName">
<word>
<element name="LastName"/>
</word>
</constraint>
<constraint name="Publish-Decade">
<range type="xs:int">
<bucket ge="2020" name="2020s">2020s</bucket>
<bucket lt="2020" ge="2010" name="2010s">2010s</bucket>
<bucket lt="2010" ge="2000" name="2000s">2000s</bucket>
<bucket lt="2000" ge="1990" name="1990s">1990s</bucket>
<bucket lt="1990" ge="1980" name="1980s">1980s</bucket>
<bucket lt="1980" ge="1970" name="1970s">1970s</bucket>
<field name="PubYear"/>
<facet-option>limit=10</facet-option>
</range>
</constraint>
<constraint name="articleTitle">
<value>
<element name="ArticleTitle"/>
</value>
</constraint>
<constraint name="model">
<range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
<element name="Article"/>
<attribute name="PubModel" />
<facet-option>limit=30</facet-option>
<facet-option>frequency-order</facet-option>
<facet-option>descending</facet-option>
</range>
</constraint>
    <transform-results apply="snippet">
    <preferred-elements>
      <element name="ArticleTitle"/>
      <element name="Abstract"/>
      <element name="LastName"/>
    </preferred-elements>
    </transform-results>
    <search:operator name="sort">
    <search:state name="relevance">
<search:sort-order direction="descending">
<search:score/>
</search:sort-order>
</search:state>
<search:state name="newest">
<search:sort-order direction="descending" type="xs:int">
<search:field name="PubYear"/>
</search:sort-order>
<search:sort-order>
<search:score/>
</search:sort-order>
</search:state>
<search:state name="oldest">
<search:sort-order direction="ascending" type="xs:int">
<search:field name="PubYear"/>
</search:sort-order>
<search:sort-order>
<search:score/>
</search:sort-order>
</search:state>
<search:state name="title">
<search:sort-order direction="ascending" type="xs:string">
<search:element name="ArticleTitle"/>
</search:sort-order>
<search:sort-order>
<search:score/>
</search:sort-order>
</search:state>
<search:state name="author-last-name">
<search:sort-order direction="ascending" type="xs:string">
<search:element name="LastName"/>
</search:sort-order>
<search:sort-order>
<search:score/>
</search:sort-order>
</search:state>
</search:operator> 
  </options>;
  declare variable $q-text :=
let $q := if(xdmp:get-request-field("advanced"))
then adv:advanced-q()
else xdmp:get-request-field("q", "sort:newest")
let $q := local:add-sort($q)
return $q;
declare variable $results := search:search($q-text, $options,
xs:unsignedLong(xdmp:get-request-field("start","1")));
declare variable $facet-size as xs:integer := 8;
declare function local:result-controller()
{
  if(xdmp:get-request-field("q"))
  then local:search-results()
  else if(xdmp:get-request-field("uri"))
  then local:article-detail()
  else local:search-results()
};
declare function local:description($article)
{
for $text in $article/search:snippet/search:match/node()
return 
  if(fn:node-name($text) eq xs:QName("search:highlight"))
then <span class="highlight">{$text/text()}</span>
else
$text
};
(: gets the current sort argument from the query string :)
declare function local:get-sort($q){
fn:replace(fn:tokenize($q," ") [fn:contains(.,"sort")],"[()]","")
};
(: adds sort to the search query string :)
declare function local:add-sort($q){
let $sortby := local:sort-controller()
return
if($sortby)
then
let $old-sort := local:get-sort($q)
let $q :=
if($old-sort)
then search:remove-constraint($q,$old-sort,$options)
else $q
return fn:concat($q," sort:",$sortby)
else $q
};
(: determines if the end-user set the sort through the drop-down or through editing
the search text field :)
declare function local:sort-controller(){
if(xdmp:get-request-field("submitbtn") or not(xdmp:get-request-field("sortby")))
then

let $order := fn:replace(fn:substring-after(fn:tokenize(xdmp:get-request-field("q","sort:newest"), " ")[fn:contains(.,"sort")],"sort:"),"[()]","")
return
if(fn:string-length($order) lt 1)
then "relevance"
else $order
else xdmp:get-request-field("sortby")
};
(: builds the sort drop-down with appropriate option selected :)
declare function local:sort-options(){
let $sortby := local:sort-controller()
let $sort-options :=
<options>
<option value="relevance">relevance</option>
<option value="newest">newest</option>
<option value="oldest">oldest</option>
<option value="LastName">author last name</option>
<option value="title">title</option>
</options>
let $newsortoptions :=
for $option in $sort-options/*
return
element {fn:node-name($option)}
{
$option/@*,
if($sortby eq $option/@value)
then attribute selected {"true"} else (),
$option/node()
}
return
<div id="sortbydiv">
sort by:
<select name="sortby" id="sortby" onchange='this.form.submit()'>
{$newsortoptions}
</select>
</div>
};
declare function local:pagination($resultspag)
{
let $start := xs:unsignedLong($resultspag/@start)
let $length := xs:unsignedLong($resultspag/@page-length)
let $total := xs:unsignedLong($resultspag/@total)
let $last := xs:unsignedLong($start + $length -1)
let $end := if ($total > $last) then $last else $total
let $qtext := $resultspag/search:qtext[1]/text()
let $next := if ($total > $last) then $last + 1 else ()
let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
let $next-href :=
if ($next)
then fn:concat("/xquery/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext)
else (),"&amp;start=",$next,"&amp;submitbtn=page")
else ()
let $previous-href :=
if ($previous)
then fn:concat("/xquery/index.xqy?q=",if ($qtext) then fn:encode-for-uri($qtext)
else (),"&amp;start=",$previous,"&amp;submitbtn=page")
else ()
let $total-pages := fn:ceiling($total div $length)
let $currpage := fn:ceiling($start div $length)
let $pagemin :=
fn:min(for $i in (1 to 4)
where ($currpage - $i) > 0
return $currpage - $i)
let $rangestart := fn:max(($pagemin, 1))
let $rangeend := fn:min(($total-pages,$rangestart + 4))
return (
<div id="countdiv"><b>{$start}</b> to <b>{$end}</b> of {$total}</div>,
local:sort-options(),
if($rangestart eq $rangeend)
then ()
else
<div id="pagenumdiv">
{ if ($previous) then <a href="{$previous-href}" title="View previous {$length} results"><img src="../assets/images/prevarrow.gif" class="imgbaseline" border="0"/></a> else () }
{
for $i in ($rangestart to $rangeend)
let $page-start := (($length * $i) + 1) - $length

let $page-href := concat("/xquery/index.xqy?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start,"&amp;submitbtn=page")

return
if ($i eq $currpage)

then <b>&#160;<u>{$i}</u>&#160;</b>

else <span class="hspace">&#160;<a href="{$page-href}">{$i}</a>&#160;</span>

}
{ if ($next) then <a href="{$next-href}" title="View next {$length} results"><img src="../assets/images/nextarrow.gif" class="imgbaseline" border="0" /></a>
 else
()}
</div>
)
};
declare function local:search-results()
{
  let $items :=
    for $article in $results/search:result
    let $uri := fn:data($article/@uri)
    let $article-doc := fn:doc($uri)
  return (
<div class="article-preview" id="articlePreview">
  <a class='title-link'  href="index.xqy?uri={xdmp:url-encode(fn:base-uri($article-doc))}">
    <h2 class="article-title" id="article-title">
      <b>{$article-doc//ArticleTitle/text()}</b>
    </h2>
  </a>
  <p class="article-abstract" id="articleAbstract"><br></br>
    {local:description($article)}
    ...&#160;
    <a href="index.xqy?uri={xdmp:url-encode($uri)}">Read More>></a>
  </p> 
  
  <span class="article-authors" id="articleAuthors">
    <b><br></br> Authors: </b>
    {fn:string-join(($article-doc//AuthorList/Author/fn:string-join((ForeName, LastName), " ")), ",
    ")}.
  </span>
  {if ($article-doc//KeywordList)
  then
  <span class="article-keywords" id="articleKeywords">
    <b> keywords: </b> {$article-doc//KeywordList/fn:string-join((Keyword), ", ")}
  </span>
  else ()
  }
  <span class="PubYear">
    <b> Published on: </b>
    {fn:data($article-doc//Journal/JournalIssue/PubDate/fn:string-join((Day,Month,Year)," "))}
  </span>
  <span class="journal-info" id="journalInfo">
    <b>Posted in: </b> {$article-doc//Journal/Title/text()}
    <br></br>
  </span>
</div>
)
return 
  if($items)
  then (local:pagination($results), $items)
  else <div>Sorry, no results for your search.<br/><br/><br/></div>
};
declare function local:article-detail()
{
    let $uri := xdmp:get-request-field("uri")
    let $article := fn:doc($uri)
    return (<div class="full-abstract" id="fullAbstract">

  <h2 class="article-title" id="article-title">
    <b>{$article/PubmedArticle/MedlineCitation/Article/ArticleTitle/text()}</b>

  </h2>

  <span class="article-authors" id="articleAuthors">
    <br></br>
    <b>written by:
    </b>{fn:string-join(($article/PubmedArticle/MedlineCitation/Article/AuthorList/Author/fn:string-join((ForeName,LastName),
    " ")), ", ")}.
  </span>

  {if ($article/PubmedArticle/MedlineCitation/Article/Abstract)
  then
  <p class="article-abstract" id="articleAbstract">
    <br></br>
    <br></br>
    {$article/PubmedArticle/MedlineCitation/Article/Abstract/fn:data(AbstractText)}
    <br></br>
    <br></br>
  </p>
  else ()
  }
  {if ($article/PubmedArticle/MedlineCitation/KeywordList)
  then
  <span class="article-keywords" id="articleKeywords">
    <b>keywords: </b>{$article/PubmedArticle/MedlineCitation/KeywordList/fn:string-join((Keyword), ", ")}.
    <br></br>
  </span>
  else ()
  }

  <span class="journal-info" id="journalInfo">
    <br></br>
    <b>Journal Information: </b>
    <br></br>

    &nbsp;&nbsp;&nbsp;<b>Title: </b> {$article/PubmedArticle/MedlineCitation/Article/Journal/Title/text()}
    <br></br>
    &nbsp;&nbsp;&nbsp;<b>Publish Date: </b>
    {fn:data($article/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/PubDate/fn:string-join((Day,Month,Year),"
    "))}
    <br></br>
    &nbsp;&nbsp;&nbsp;<b>ISSN: </b> {$article/PubmedArticle/MedlineCitation/Article/Journal/ISSN/text()}
    <br></br>
    &nbsp;&nbsp;&nbsp;
    {if ($article/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/Issue) then
      (
        <span>
         <b>Issue: </b> {$article/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/Issue/text()}
    <br></br>
    </span>
      )
    else
      ()}
    &nbsp;&nbsp;&nbsp;
    {if ($article/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/Volume) then
      (<span>
      <b>Volume: </b>
    {$article/PubmedArticle/MedlineCitation/Article/Journal/JournalIssue/Volume/text()}
    <br></br>
    </span>)
    else
      ()}
  </span>
</div>)
};
declare function local:facets()
{
for $facet in $results/search:facet
let $facet-count := fn:count($facet/search:facet-value)
let $facet-name := fn:data($facet/@name)
return
if($facet-count > 0)
then <div class="facet">
<div class="purplesubheading">
<img src="../assets/images/checkblank.gif"/>{$facet-name}</div>
{
  let $facet-items :=
for $val in $facet/search:facet-value

let $print := if($val/text()) then $val/text() else "Unknown"
let $qtext := ($results/search:qtext)
let $sort := local:get-sort($qtext)
let $this :=
if (fn:matches($val/@name/string(),"\W"))
then fn:concat('"',$val/@name/string(),'"')
else if ($val/@name eq "") then '""'
else $val/@name/string()

let $this := fn:concat($facet/@name,':',$this)
let $selected := fn:matches($qtext,$this,"i")

let $icon :=
if($selected)

then <img src="../assets/images/checkmark.gif"/>
else <img src="../assets/images/checkblank.gif"/>

let $link :=
if($selected)

then search:remove-constraint($qtext,$this,$options)
else if(fn:string-length($qtext) gt 0)
then fn:concat("(",$qtext,")"," AND ",$this)
else $this

let $link := if($sort and fn:not(local:get-sort($link))) then
fn:concat($link," ",$sort) else $link
let $link := fn:encode-for-uri($link)
return
<div class="facet-value">{$icon}<a class="facet-link" href="index.xqy?q={$link}">
{fn:lower-case($print)}</a> [{fn:data($val/@count)}]</div>
return (
<div>{$facet-items[1 to $facet-size]}</div>,
if($facet-count gt $facet-size)
then (
    <div class="facet-hidden" id="{$facet-name}">{$facet-items[position() gt $facet-size]}</div>,
    <div class="facet-toggle" id="{$facet-name}_more"><img src="../assets/images/checkblank.gif"/><a href="javascript:toggle('{$facet-name}');" class="white">more...</a></div>,
    <div class="facet-toggle-hidden" id="{$facet-name}_less"><img src="../assets/images/checkblank.gif"/><a href="javascript:toggle('{$facet-name}');" class="white">less...</a></div>
)


else ()
)
}
</div>

else <div>&#160;</div>
};



xdmp:set-response-content-type("text/html; charset=utf-8"),
'
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html lang="en" xmlns="http://www.w3.org/1999/xhtml">

<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Pubmed Articles</title>
  <link rel="stylesheet" href="/assets/css/pubmed.css" type="text/css" />
  <script src="../js/pubmed.js" type="text/javascript"/>
</head>

<body>
 
  <div class="header-container">
    <header class="header">
       <a href="/xquery/index.xqy" class="link-title">
      <h1 class="title">Pubmed Articles</h1>
       </a>
    </header>
    <div class="form-container">
      <span class="sub-title">How can we help you?</span>
      <form  name="form1" method="get" action="/xquery/index.xqy" id="form1" class="form1" >

        <div id="searchContainer" class="search-container">

          <input class="search-box" type="text" name="q" id="q" size="50" value="{$q-text}"/>
          <button type="button" id="resetButton" onclick="
			  	document.getElementById('q').value = ''; 
				document.location.href='index.xqy'
				" class="reset-button">
            x
          </button>
          <input type="submit" id="submitbtn" name="submitbtn" value="search" class="submit-button" />
        </div>

        <div id="advancedContainer" class="advanced-container">
        <a href="./advanced.xqy" class="text">Advanced Search</a>
    </div>
  <div class="content-container">
    <div id="detailsContainer" class="details-container">

      { local:result-controller() }

    </div>
    <div id="facetsContainer" class="facets-container">
        {local:facets()}
    </div>
  </div>
      </form>
    </div>
  </div>
  
    
  
</body>

</html>