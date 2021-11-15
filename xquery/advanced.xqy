xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at
"/MarkLogic/appservices/search/search.xqy";
declare variable $options-model :=
<options xmlns="http://marklogic.com/appservices/search">
<return-results>false</return-results>
<return-facets>true</return-facets>
<constraint name="PubModel">
<range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB" facet="true">
<element name="Article"/>
<attribute name="PubModel"/>
<facet-option>ascending</facet-option>
</range>
</constraint>
</options>;
declare function local:list-model-vals()
{
for $model in search:search("", $options-model)//search:facet-value
return <option value="{fn:data($model/@name)}">
{fn:lower-case($model/text())} [{fn:data($model/@count)}]</option>
};
xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',

<html lang="en" xmlns="http://www.w3.org/1999/xhtml">

<head>
  <meta charset="UTF-8" />
  <meta http-equiv="X-UA-Compatible" content="IE=edge" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Pubmed Articles</title>
  <link rel="stylesheet" href="/assets/css/pubmed.css" type="text/css" />
  <script type="text/javascript" src="../autocomplete/lib/prototype/prototype.js"></script>
  <script type="text/javascript" src="../autocomplete/lib/scriptaculous/scriptaculous.js"></script>
  <script type="text/javascript" src="../autocomplete/src/autocomplete.js"></script>
  <script type="text/javascript" src="../autocomplete/src/lib.js"></script>
</head>

<body>

  <div class="header-container">
    <header class="header">
      <a class ="link-title" href="/xquery/index.xqy">
      <h1 class="title">Pubmed Articles</h1>
      </a>
    </header>
    <div class="form-container">
      <span class="sub-title">How can we help you?</span>
      
    </div>
  </div>

    
  <div class="content-container">
    <div id="detailsContainer" class="details-container">

<div id="rightcol">
  <div id="searchdiv">
  <form name="formadv" method="get" action="index.xqy" id="formadv">
  <input type="hidden" name="advanced" value="advanced"/>
  <table border="0" cellspacing="8">
    <tr>
      <td align="right">&#160;</td>
      <td colspan="4" class="songnamelarge"><span class="tiny">&#160;&#160;</span><br />
        advanced search<br />
        <span class="tiny">&#160;&#160;</span></td>
    </tr>
    <tr>
      <td align="right">Search for:</td>
      <td colspan="4"><input type="text" name="keywords" id="keywords" size="40"/>
        &#160;
        <select name="type" id="type">
          <option value="all">all of these words</option>
          <option value="any">any of these words</option>
          <option value="phrase">exact phrase</option>
        </select></td>
    </tr>
    <tr>
      <td align="right">Words to exclude:</td>
      <td colspan="4"><input type="text" name="exclude" id="exclude" size="40"/></td>
    </tr>
    <tr>
      <td align="right">Model:</td>
      <td colspan="4"><select name="model" id="model">
        <option value="all">all</option>
        {local:list-model-vals()}
      </select></td>
    </tr>
    <tr>
      <td align="right">Author:</td>
      <td colspan="4"><input type="text" name="authorLastName" id="authorLastName" size="40"/></td>
    </tr>
    <tr>
      <td align="right">Article title:</td>
      <td colspan="4"><input type="text" name="articleTitle" id="articleTitle" size="40" autocomplete="off"/></td>
    </tr>
    <tr valign="top">
      <td align="right">&#160;</td>
      <td><span class="tiny">&#160;&#160;</span><br /><input type="submit" name="submitbtn" id="submitbtn" value="search"/></td>
      <td>&#160;</td>
      <td>&#160;</td>
      <td>&#160;</td>
    </tr>
  </table>
  </form>
  </div>
</div>

    </div>
    
  </div>
</body>

</html>