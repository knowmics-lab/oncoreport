while getopts ':t:i:o:' flag; do
  case "${flag}" in
  t) tumortype=${OPTARG} ;;
  i) id_pt=${OPTARG} ;;
  o) output=${OPTARG} ;;
  esac
done
#printf "<html>\n<body>\n<h2>ESMO information for $tumortype cancer</h2>\n<dl>\n" >>$tumortype.html
printf "<html>\n<body>\n<h2>ESMO information for $tumortype cancer</h2>\n<dl>\n" >>$output/$tumortype.html
echo "Tumor Type: $tumortype"
#grep -B 1 -A 1 -i "$tumortype" project/html_source/esmo/guidelinesTOC.txt | while read -r line1; do
grep -B 1 -A 1 -i "$tumortype" $ONCOREPORT_ESMO_PATH/guidelinesTOC.txt | while read -r line1; do
  echo "Process GuideLines"
  if [[ "$line1" == *"guidelineID"* ]]; then
    gl_id=$(sed -e 's/"guidelineID": \(.*\),/\1/' <<<$line1)
    #echo "Guidelines ID: $gl_id"
  fi
  if [[ "$line1" == *"guidelineName"* ]]; then
    gl_name=$(sed -e 's/"guidelineName": "\(.*\)",/\1/' <<<$line1)
    #echo "Category name: $gl_name"
  fi
  if [[ "$line1" == *"cmsID"* ]]; then
    t_id=$(sed -e 's/"cmsID": "\(.*\)",/\1/' <<<$line1)
    #echo "Tumor ID: $t_id"
  fi
  echo "$gl_id , $gl_name , $t_id"
  if [[ -z $t_id ]]; then
    echo "Empty par"
    #continue
  else
 #   if grep -q $t_id project/html_source/esmo/idx.json; then
    if grep -q $t_id $ONCOREPORT_ESMO_PATH/idx.json; then
      #echo "### ../../report_html/${id_pt}/${tumortype}.html"
      #printf "<dt>$gl_name</dt>\n" >>$tumortype.html
      printf "<dt>$gl_name</dt>\n" >>$output/$tumortype.html
      #printf "<div class="panel"><div class="panel-heading"> $gl_name </div>" >>project/report_html/${id_pt}/esmo_${tumortype}.html
      printf "<div class="panel"><div class="panel-heading"> $gl_name </div>" >>$output/esmo_${tumortype}.html
      #grep -A 1 $t_id project/html_source/esmo/idx.json | while read -r line2; do
      grep -A 1 $t_id $ONCOREPORT_ESMO_PATH/idx.json | while read -r line2; do
        if [[ "$line2" == *"jumpto"* ]]; then
          jumpto=$(sed -e 's/"jumpto":"\(.*\)",/\1/' <<<$line2)
          #		echo "Name to jump: $jumpto"
        fi
        if [[ "$line2" == *"name"* ]]; then
          subcat=$(sed -e 's/"name":"\(.*\)"/\1/' <<<$line2)
          #		echo "Subcategory: $subcat"
        fi
        if [[ -z $subcat ]]; then
          echo 'one or more variables are undefined'
          #continue
        else
          #printf "$gl_id\t$jumpto\t$subcat\n" >>$tumortype.txt
          printf "$gl_id\t$jumpto\t$subcat\n" >>$output/$tumortype.txt
          echo -e "\t http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/Html/GL$gl_id/$jumpto.html"
          jumpto=""
          subcat=""
        fi
      done
      if [ -f "$output/${tumortype}.txt" ]; then
        #sort -V -k 2 -o "${tumortype}"_sorted.txt "${tumortype}".txt
        sort -V -k 2 -o "${output}/${tumortype}"_sorted.txt "${output}/${tumortype}".txt
        OLDIFS=$IFS
        while read -r line3; do
          echo "test $line3"
          IFS=$'\t'
          read -a strarr <<<"$line3"
          gl=${strarr[0]}
          enas=${strarr[1]}
          descr=${strarr[2]}
          echo "$gl - $enas - $descr"
          category=$(echo ${strarr[1]} | awk -F'_' '{print $2}')
          echo "${category}"
          IFS=.
          read -a catsplit <<<"${category}"
          #	echo "---${catsplit[0]} - ${catsplit[1]} - ${catsplit[2]} - ${catsplit[3]}"
          #	echo "$gl - $enas - $descr"
          v1=${catsplit[0]}
          v2=${catsplit[1]}
          v3=${catsplit[2]}
          v4=${catsplit[3]}
          IFS=$OLDIFS
          lastused="-"
          #printf "<dd> <a href="http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/Html/GL${gl}/${enas}.html">${descr}</a></dd>\n" >>$tumortype.html
          printf "<dd> <a href="http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/Html/GL${gl}/${enas}.html">${descr}</a></dd>\n" >>$output/$tumortype.html
          #printf "<button type=\"button\" class=\"button-esmo\" onclick=\"setURL('http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/Html/GL${gl}/${enas}.html')\">${descr}</button>\n" >>project/report_html/${id_pt}/esmo_${tumortype}.html
          printf "<button type=\"button\" class=\"button-esmo\" onclick=\"setURL('http://interactiveguidelines.esmo.org/esmo-web-app/media/data/EN/Html/GL${gl}/${enas}.html')\">${descr}</button>\n" >>$output/esmo_${tumortype}.html

          IFS=.
          read -a prev_cat <<<"${category}"
          p1=${prev_cat[0]}
          p2=${prev_cat[1]}
          p3=${prev_cat[2]}
          p4=${prev_cat[3]}
        #done <"${tumortype}"_sorted.txt
        done <"${output}/${tumortype}"_sorted.txt
        IFS=$OLDIFS
        #rm "${tumortype}".txt
        #rm "${tumortype}"_sorted.txt
        rm "${output}/${tumortype}".txt
        rm "${output}/${tumortype}"_sorted.txt
      fi
      prev_cat=""
      gl_id=""
      gl_name=""
      t_id=""
      #printf "</div>" >>${tumortype}_test.html
      printf "</div>" >>${output}/${tumortype}_test.html
    fi
  fi
done
#printf "</dl>\n</body>\n</html>" >>$tumortype.html
#printf "</div>" >>project/report_html/${id_pt}/esmo_${tumortype}.html
printf "</dl>\n</body>\n</html>" >>$output/$tumortype.html
printf "</div>" >>${output}/esmo_${tumortype}.html
