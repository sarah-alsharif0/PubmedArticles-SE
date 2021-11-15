module namespace adv = "http://marklogic.com/MLU/top-songs/advanced";
declare function advanced-q()
{
    let $keywords := fn:tokenize(xdmp:get-request-field("keywords")," ")
    let $type := xdmp:get-request-field("type")
    let $exclude := fn:tokenize(xdmp:get-request-field("exclude")," ")
    let $model := xdmp:get-request-field("model")
    let $model := if ($model eq "all")
                    then ""
                    else $model

    let $author := xdmp:get-request-field("authorLastName")
    let $articleTitle := xdmp:get-request-field("articleTitle")
    let $keywords := if($keywords)
                        then if($type eq "any")
                                then fn:string-join($keywords," OR ")
                        else if($type eq "phrase")
                                then fn:concat('"',fn:string-join($keywords," "),'"')
                                else $keywords
                        else ()

    let $exclude := if($exclude)
                        then fn:string-join((
                            for $i in $exclude
                            return fn:concat("-",$i))," ")
                        else ()

    let $model := if($model)
                    then if (fn:matches($model,"\W"))
                            then fn:concat('model:"',$model,'"')
                            else fn:concat("model:",$model)
                    else ()

    let $author := if($author)
                    then if (fn:matches($author,"\W"))
                            then fn:concat('authorLastName:"',$author,'"')
                            else fn:concat("authorLastName:",$author)
                    else ()

    let $articleTitle := if($articleTitle)
                            then if (fn:matches($articleTitle,"\W"))
                                    then fn:concat('articleTitle:"',$articleTitle,'"')
                                    else fn:concat("articleTitle:",$articleTitle)
                            else ()

    let $q-text := fn:string-join(($keywords, $exclude,$model, $author,$articleTitle)," ")
    return $q-text
};