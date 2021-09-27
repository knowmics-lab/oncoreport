wget http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/SearchFiles/idx.json
#grep -B 1 interactive\ tool idx.json > interactive_tool.txt
#sed -e 's/"jumpto":"\(.*\)",/\1/' interactive_tool.txt | grep -E "ENAS|interactive_" > jump_to_interactive.txt
#grep "\"name\":" interactive_tool.txt | sed -e 's/"name":"\(.*\)"/\1/' > name_interactive.txt
wget http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/TOCJson/guidelinesTOC.json
#grep -E "guidelineID|guidelineName|guidelineAbbrName|cmsID" guidelinesTOC.json > guidelinesTOC.txt
grep -E "guidelineID|guidelineName|cmsID" guidelinesTOC.json > guidelinesTOC.txt
