xquery version "1.0-ml";

import module namespace search ="http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";    

declare option xdmp:mapping "false";
(: This line is required in v4.2 of ML Server for JavaScript to function properly :) 
declare option xdmp:output 'indent=no';

declare variable $options as node() := 
    <options >
        <default-suggestion-source>
            <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB">
                <element name="ArticleTitle"/>
            </range>
        </default-suggestion-source>
    </options>;

(: cts:query way :)
declare function local:get-suggestions($qname as xs:string,$q as xs:string){
    for $i in cts:element-value-match(xs:QName($qname),fn:concat("*",$q,"*"), "collation=http://marklogic.com/collation/en/S1/AS/T00BB")
    return element suggestion {$i}
};

(: searchapi way :)
(: filed bug :)
declare function local:search-suggestions($q as xs:string){
    for $i in search:suggest($q,$options) 
    return element suggestion {fn:substring(fn:substring($i,1,fn:string-length($i)-1),2)}
};


let $r := xdmp:set-response-content-type("text/xml")
let $q := xdmp:get-request-field("q")
return
    if($q)
    then
        <Suggestions>
            {local:get-suggestions("ArticleTitle",$q)}
        </Suggestions>
    else ()