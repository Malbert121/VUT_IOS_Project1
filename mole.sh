#!/bin/sh

for last; do true; done
my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
export POSIXLY_CORRECT=yes

if [ -z "$MOLE_RC" ]; then
	exit 115
elif [ ! -e "$MOLE_RC" ]; then
	touch $MOLE_RC
elif [ -e "$MOLE_RC" ]; then
	:
else
	exit 113
fi

if [ ! -z "$EDITOR" ]; then
	edit="$EDITOR"
elif [ ! -z "$VISUAL" ]; then
	edit="$VISUAL"
else
	edit="vi"
fi

help(){
echo "-h – Vypíše nápovědu k použití skriptu."
echo "mole [-g GROUP] FILE – Zadaný soubor bude otevřen."
echo "	Pokud byl zadán přepínač -g, dané otevření souboru bude zároveň přiřazeno do skupiny s názvem GROUP. GROUP může být název jak existující, tak nové skupiny."
echo "mole [-m] [FILTERS] [DIRECTORY] – Pokud DIRECTORY odpovídá existujícímu adresáři, skript z daného adresáře vybere soubor, který má být otevřen."
echo "	Pokud nebyl zadán adresář, předpokládá se aktuální adresář."
echo "	Pokud bylo v daném adresáři editováno skriptem více souborů, vybere se soubor, který byl pomocí skriptu otevřen (editován) jako poslední."
echo "	Pokud byl zadán argument -m, tak skript vybere soubor, který byl pomocí skriptu otevřen (editován) nejčastěji."
echo "	Pokud bude při použití přepínače -m nalezeno více souborů se stejným maximálním počtem otevření, může mole vybrat kterýkoliv z nich."
echo "Výběr souboru může být dále ovlivněn zadanými filtry FILTERS."
echo "	Pokud nebyl v daném adresáři otevřen (editován) ještě žádný soubor, případně žádný soubor nevyhovuje zadaným filtrům, jedná se o chybu."
echo "mole list [FILTERS] [DIRECTORY] – Skript zobrazí seznam souborů, které byly v daném adresáři otevřeny (editovány) pomocí skriptu."
echo "	Pokud nebyl zadán adresář, předpokládá se aktuální adresář."
echo "	Seznam souborů může být filtrován pomocí FILTERS."
echo "	Seznam souborů bude lexikograficky seřazen a každý soubor bude uveden na samostatném řádku."
echo "	Každý řádek bude mít formát FILENAME:<INDENT>GROUP_1,GROUP_2,..., kde FILENAME je jméno souboru (i s jeho případnými příponami), "
echo "<INDENT> je počet mezer potřebných k zarovnání a GROUP_* jsou názvy skupin, u kterých je soubor evidován."
echo "	Seznam skupin bude lexikograficky seřazen."
echo "	Pokud budou skupiny upřesněny pomocí přepínače -g (viz sekce FILTRY), uvažujte při výpisu souborů a skupin pouze záznamy patřící do těchto skupin."
echo "	Pokud soubor nepatří do žádné skupiny, bude namísto seznamu skupin vypsán pouze znak -."
echo "	Minimální počet mezer použitých k zarovnání (INDENT) je jedna. Každý řádek bude zarovnán tak, aby seznam skupin začínal na stejné pozici. Tedy např:"
echo "		FILE1:  grp1,grp2"
echo "		FILE10: grp1,grp3"
echo "		FILE:   -"
echo ""
echo "Filtry"
echo ""
echo "FILTERS může být kombinace následujících filtrů (každý může být uveden maximálně jednou):"
echo "		[-g GROUP1[,GROUP2[,...]]] – Specifikace skupin. Soubor bude uvažován (pro potřeby otevření nebo výpisu) pouze tehdy, pokud jeho spuštění spadá alespoň do jedné z těchto skupin."
echo "		[-a DATE] - Záznamy o otevřených (editovaných) souborech před tímto datem včetně (volitelně lze implementovat i jako striktně před uvedeným datem; UPDATED 22.3.) nebudou uvažovány."
echo "		[-b DATE] - Záznamy o otevřených (editovaných) souborech po tomto datu včetně (volitelně lze implementovat i jako striktně po uvedeném datu; UPDATED 22.3.) nebudou uvažovány."
echo "		Argument DATE je ve formátu YYYY-MM-DD."

}

if [ "$1" = "secret-log" ]; then
	shift
	while getopts ":a:b:" opt; do
  	case $opt in
    a) after="$OPTARG"
	if date -d "$after" >/dev/null 2>&1; then
	    :
	else
    	echo "$after is invalid date"
		exit 228
	fi
    ;;
	b) before="$OPTARG"
	if date -d "$before" >/dev/null 2>&1; then
	    :
	else
    	echo "$before is invalid date"
		exit 228
	fi
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
		exit 122
    ;;
  esac
done
	my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
	touch ~/.mole/log_"$USER"_"$my_date"
	if [ ! -z "$after" ] && [ ! -z "$before" ]; then
		dirdir=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' | awk -F',' -v date="$after" -v dates="$before" '{ if (substr($5, length($5)-20) > date && substr($5, length($5)-20) < dates) {print}}' | awk -F',' 'NR>0 { if(max==""){max=$3;file=$2;dir=$1}; if(length($2)>max) {max=length($2);file=$2;dir=$1}} END { print NR }')
			for i in $(seq 1 $dirdir)
			do
				sec_text=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' | awk -F',' -v date="$after" -v dates="$before" '{ if (substr($5, length($5)-20) > date && substr($5, length($5)-20) < dates) {print}}' | awk -F',' -v line="$i" 'NR==line{print $1"/"$2";"$5}')
				echo $sec_text  >> ~/.mole/log_"$USER"_"$my_date"
			done
	elif [ ! -z "$after" ]; then
		dirdir=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' | awk -F',' -v date="$after" '{ if (substr($5, length($5)-20) > date) {print}}' | awk -F',' 'NR>0 { if(max==""){max=$3;file=$2;dir=$1}; if(length($2)>max) {max=length($2);file=$2;dir=$1}} END { print NR }')
			for i in $(seq 1 $dirdir)
			do
				sec_text=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' | awk -F',' -v date="$after" '{ if (substr($5, length($5)-20) > date) {print}}' | awk -F',' -v line="$i" 'NR==line{print $1"/"$2";"$5}')
				echo $sec_text  >> ~/.mole/log_"$USER"_"$my_date"
			done
	elif [ ! -z "$before" ]; then
		dirdir=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' | awk -F','  -v dates="$before" '{ if ( substr($5, length($5)-20) < dates) {print}}' | awk -F',' 'NR>0 { if(max==""){max=$3;file=$2;dir=$1}; if(length($2)>max) {max=length($2);file=$2;dir=$1}} END { print NR }')
			for i in $(seq 1 $dirdir)
			do
				sec_text=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' |  awk -F','  -v dates="$before" '{ if ( substr($5, length($5)-20) < dates) {print}}' | awk -F',' -v line="$i" 'NR==line{print $1"/"$2";"$5}')
				echo $sec_text  >> ~/.mole/log_"$USER"_"$my_date"
			done
	else
		dirdir=$(awk -F',' 'NR>0 { if(max==""){max=$3;file=$2;dir=$1}; if(length($2)>max) {max=length($2);file=$2;dir=$1}} END { print NR }' $MOLE_RC )
			for i in $(seq 1 $dirdir)
			do
				sec_text=$( awk -F',' '{print}' "$MOLE_RC" | sed 's/\[[^]]*\]//g' | awk -F',' -v line="$i" 'NR==line{print $1"/"$2";"$5}')
				echo $sec_text  >> ~/.mole/log_"$USER"_"$my_date"
			done
	fi
	 	sort ~/.mole/log_"$USER"_"$my_date" > tmpfile && mv tmpfile ~/.mole/log_"$USER"_"$my_date"
	 	bzip2 ~/.mole/log_"$USER"_"$my_date"
		exit 0
else
	:
fi



if [ "$1" = "list" ]; then
	shift
	while getopts "::a:b:g:" opt; do
  case $opt in
    g ) grup="$OPTARG"
    ;;
    a) after="$OPTARG"
	if date -d "$after" >/dev/null 2>&1; then
	    :
	else
    	echo "$after is invalid date"
		exit 228
	fi
    ;;
	b) before="$OPTARG"
	if date -d "$before" >/dev/null 2>&1; then
	    :
	else
    	echo "$before is invalid date"
		exit 228
	fi
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
		exit 122
    ;;
  esac
done

	if [ -d "$last" ]; then
		:
	else
		echo "Not directory."
		echo 99
	fi

	if [ ! -z "$after" ] && [ ! -z "$before" ]; then
	:
	elif [ ! -z "$after" ]; then
	:
	elif [ ! -z "$before" ]; then
	:
	else
		indent=$(awk -F',' -v dir="$last" '{ if( $1 == dir )  {print}}' "$MOLE_RC" | awk -F',' 'NR>0 { if(max==""){max=$3;file=$2;dir=$1}; if(length($2)>max) {max=length($2);file=$2;dir=$1}} END { print max }' )
		dirdir=$(awk -F',' 'NR>0 { if(max==""){max=$3;file=$2;dir=$1}; if(length($2)>max) {max=length($2);file=$2;dir=$1}} END { print NR }' $MOLE_RC )

	for i in $(seq 1 $dirdir)
	do
		file=$(awk -F',' -v dir="$last" -v line=$i 'NR==line{ if( $1 == dir )  {print}}' "$MOLE_RC" | awk -F ',' -v line=$i '{print $2}' )
		grap=$(awk -F',' -v dir="$last" -v line=$i 'NR==line{ if( $1 == dir )  {print}}' "$MOLE_RC" | awk -F ',' -v line=$i '{print $4}' )
	if [ -z "$file" ]; then
		continue
	else
		:
	fi
	if [ ${#grap} -eq 1 ]; then
		:
	else
	grap=$(echo "${grap}" | sed "s/-/,/g")
	grap=$(echo $grap | cut -c 2- | rev | cut -c 2- | rev)
	fi
	inden=$(( $indent - ${#file} + 1))
	if [ ! -z "$grup" ]; then
		if echo "$grap" | grep -q "$grup"; then
  			printf "%s:%${inden}s%s\n" "$file" "" "$(echo "$grap")"
		else
  			:
		fi
	else
		printf "%s:%${inden}s%s\n" "$file" "" "$(echo "$grap")"
	fi
		done
	fi

	exit 0
else
	:
fi

group_this(){
	dir=$(dirname $last)
	file=$(basename $last)
  if grep -Eq "$dir,$file" "$MOLE_RC"; then
  	if grep -Eq "$dir,$file" "$MOLE_RC"; then
  		line=$(grep -En "$dir,$file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
  		num=$(sed -n "${line} s/^[^,]*,[^,]*,\([^,]*\),.*$/\1/p" ${MOLE_RC})
  		num=$((num + 1))
  		sed -i "${line} s/^\([^,]*,[^,]*,\)[^,]*\(.*\)$/\1$num\2/" $MOLE_RC
		my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
		my_date=$my_date"["$grup"]"
		"$edit" "$last"
		err=$(echo $?)
  		sed -i "${line} s/$/${my_date};/" $MOLE_RC
		if sed -n "${line}p" $MOLE_RC | grep -q "$grup-" ; then
			:
		else
			sed -i "${line} s/-,/-${grup}-,/" $MOLE_RC
		fi
  	else
  		newfile=$dir","$file",1,-,"$my_date";"
  		echo $dir","$file",1,-$arg1-,"$my_date";" >> $MOLE_RC
  	fi
  else
  	echo $dir","$file",1,-"$arg1"-,"$my_date";" >> $MOLE_RC
  fi
}

find_group(){
	latest_line=$(date "${arg1},*,*,*,*+%Y-%m-%d_%H-%M-%S"  "$(stat -c '%y' "$MOLE_RC")")
	latest_line=$(grep -En "$latest_line" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/')
	echo $latest_line
}

popular(){
	if [ ! -z "$after" ] && [ ! -z "$before" ]; then
		pop_dir=$(awk -F',' -v date="$after" -v dates="$before" '{ if (substr($5, length($5)-20) > date && substr($5, length($5)-20) < dates) {print}}' "$MOLE_RC" | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print dir }')
		pop_file=$(awk -F',' -v date="$after" -v dates="$before" '{ if (substr($5, length($5)-20) > date && substr($5, length($5)-20) < dates) {print}}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print file }')
		pop_file=$(grep -En "$pop_dir,$pop_file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	elif [ ! -z "$after" ]; then
		pop_dir=$(awk -F',' -v date="$after" 'substr($5, length($5)-20) > date {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print dir }')
		pop_file=$(awk -F',' -v date="$after" 'substr($5, length($5)-20) > date {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print file }')
		pop_file=$(grep -En "$pop_dir,$pop_file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	elif [ ! -z "$before" ]; then
		pop_dir=$(awk -F',' -v date="$before;$" 'substr($5, length($5)-20) < date {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print dir }')
		pop_file=$(awk -F',' -v date="$before;$" 'substr($5, length($5)-20) < date {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print file }')
		pop_file=$(grep -En "$pop_dir,$pop_file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	else
		pop_file=$(awk -F ',' 'NR>0{if(max==""){max=$3;line=1}; if($3>max) {max=$3;line=NR}} END { print line }' "$MOLE_RC")
	fi
	echo $pop_file
	if [ -z "$pop_file" ]; then
    	exit 25
	else
    	:
	fi

	file=$(awk -F ',' -v line=$pop_file 'NR==line{print $2}' $MOLE_RC )
	dir=$(awk -F ',' -v line=$pop_file 'NR==line{print $1}' $MOLE_RC )
	num=$(sed -n "${pop_file} s/^[^,]*,[^,]*,\([^,]*\),.*$/\1/p" ${MOLE_RC})
	num=$((num + 1))
	sed -i "${pop_file} s/^\([^,]*,[^,]*,\)[^,]*\(.*\)$/\1$num\2/" $MOLE_RC
	"$edit" "$dir/$file"
	err=$(echo $?)
	my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
	sed -i "${pop_file} s/$/${my_date};/" $MOLE_RC

}

popular_group(){
	if [[ ! -z "$after" ]] && [[ ! -z "$before" ]]; then
		pop_dir=$( awk -F',' -v date="$after" 'substr($5, length($5)-19) > date && index($3, group) > 0 {print}' $MOLE_RC | awk -F',' -v date="$before" -v group="$grup" '$5 < date {print}' | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print dir }')
		pop_file=$(awk -F',' -v date="$after" 'substr($5, length($5)-19) > date && index($3, group) > 0 {print}' $MOLE_RC | awk -F',' -v date="$before" -v group="$grup" '$5 < date {print}' | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print file }')
		pop_file=$(grep -En "$pop_dir,$pop_file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	elif [ ! -z "$after" ]; then
		pop_dir=$(awk -F',' -v date="$after" -v group="$grup" 'substr($5, length($5)-19) > date && index($3, group) > 0 {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print dir }')
		pop_file=$(awk -F',' -v date="$after" -v group="$grup" 'substr($5, length($5)-19) > date && index($3, group) > 0  {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print file }')
		pop_file=$(grep -En "$pop_dir,$pop_file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	elif [ ! -z "$before" ]; then
		pop_dir=$(awk -F',' -v date="$before" -v group="$grup" 'substr($5, length($5)-19) < date && index($3, group) > 0 {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print dir }')
		pop_file=$(awk -F',' -v date="$before" -v group="$grup" 'substr($5, length($5)-19) < date && index($3, group) > 0 {print}' $MOLE_RC | awk -F ',' 'NR>1 {if(max==""){max=$3;file=$2;dir=$1}; if($3>max) {max=$3;file=$2;dir=$1}} END { print file }')
		pop_file=$(grep -En "$pop_dir,$pop_file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	else
		pop_file=$(awk -F ',' 'NR>1{if(max==""){max=$3;line=2}; if($3>max) {max=$3;line=NR}} END { print line }' "$MOLE_RC")
	fi
	if [ -z "$pop_file" ]; then
    	exit 25
	else
    	:
	fi
	echo $pop_file
	file=$(awk -F ',' -v line=$pop_file 'NR==line{print $2}' $MOLE_RC )
	dir=$(awk -F ',' -v line=$pop_file 'NR==line{print $1}' $MOLE_RC )
	num=$(sed -n "${pop_file} s/^[^,]*,[^,]*,\([^,]*\),.*$/\1/p" ${MOLE_RC})
	num=$((num + 1))
	sed -i "${pop_file} s/^\([^,]*,[^,]*,\)[^,]*\(.*\)$/\1$num\2/" $MOLE_RC
	"$edit" "$dir/$file"
	err=$(echo $?)
	my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
	my_date=$my_date"["$grup"]"
	sed -i "${pop_file} s/$/${my_date};/" $MOLE_RC

}

last_group(){
	my_date=$my_date"["$grup"]"
 	latest_line=$(grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}\[${grup}]" $MOLE_RC | sort -r | head -n 1 | tail -n 1 )
	latest_line=$(echo "${latest_line%%\[${grup}]}")
	latest_line=$(grep -En "$latest_line" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
	file=$(awk -F ',' -v line=$latest_line 'NR==line{print $2}' $MOLE_RC )
	dir=$(awk -F ',' -v line=$latest_line 'NR==line{print $1}' $MOLE_RC )
	num=$(sed -n "${latest_line} s/^[^,]*,[^,]*,\([^,]*\),.*$/\1/p" ${MOLE_RC})
	num=$((num + 1))
	sed -i "${latest_line} s/^\([^,]*,[^,]*,\)[^,]*\(.*\)$/\1$num\2/" $MOLE_RC
	"$edit" "$dir/$file"
	err=$(echo $?)
	my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
	my_date=$my_date"["$grup"]"
	sed -i "${latest_line} s/$/${my_date};/" $MOLE_RC
}

while getopts ":a:b:mg:h" opt; do
  case $opt in
	h) help
	exit 33
	;;
    m) most=1
    ;;
    g) grup="$OPTARG"
    ;;
    a) after="$OPTARG"
	if date -d "$after" >/dev/null 2>&1; then
	    :
	else
    	echo "$after is invalid date"
		exit 228
	fi
    ;;
	b) before="$OPTARG"
	if date -d "$before" >/dev/null 2>&1; then
	    :
	else
    	echo "$before is invalid date"
		exit 228
	fi
    ;;
    \?) echo "Invalid option -$OPTARG" >&2
		exit 122
    ;;
  esac
done


if [ ! -z "$grup" ] && [ ! -z "$most" ]; then
	popular_group
	exit 0
elif [ ! -z "$grup" ]; then
 	if [ -e "$last" ]; then
     	if [ -f "$last" ]; then
     	    group_this
			exit 0
     	else
     	    echo "The path is not a file or directory."
 			exit 12
     	fi
 	else
     	last_group
		exit 0
 	fi
elif [ ! -z "$most" ]; then
	popular
	exit 0
else
	:
fi



if [ $# -eq 0 ] && [ ! -e "$last" ]; then
	latest_line=$(grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}" $MOLE_RC | sort -r | head -n 1 | tail -n 1)
	latest_line=$(grep -En "$latest_line" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/')
	file=$(awk -F ',' -v line=$latest_line 'NR==line{print $2}' $MOLE_RC )
	dir=$(awk -F ',' -v line=$latest_line 'NR==line{print $1}' $MOLE_RC )
	num=$(sed -n "${latest_line} s/^[^,]*,[^,]*,\([^,]*\),.*$/\1/p" ${MOLE_RC})
	num=$((num + 1))
	sed -i "${latest_line} s/^\([^,]*,[^,]*,\)[^,]*\(.*\)$/\1$num\2/" $MOLE_RC
	my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
	sed -i "${latest_line} s/$/${my_date};/" $MOLE_RC
elif [ -e "$last" ]; then
  dir=$(dirname $last)
  file=$(basename $last)  
  ed_line=$((dir_line + 1))
  if grep -Eq "$dir,$file" "$MOLE_RC"; then
  	if grep -Eq "$dir,$file" "$MOLE_RC"; then
  		line=$(grep -En "$dir,$file" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
  		num=$(sed -n "${line} s/^[^,]*,[^,]*,\([^,]*\),.*$/\1/p" ${MOLE_RC})
  		num=$((num + 1))
  		sed -i "${line} s/^\([^,]*,[^,]*,\)[^,]*\(.*\)$/\1$num\2/" $MOLE_RC
		"$edit" "$last"
		err=$(echo $?)
		my_date=$(date +%Y-%m-%d)"_"$(date +%H-%M-%S)
  		sed -i "${line} s/$/${my_date};/" $MOLE_RC
  	else
  		newfile=$dir","$file",1,-,"$my_date";"
  		echo $dir","$file",1,-,"$my_date";" >> $MOLE_RC
  	fi
  else
  	echo $dir","$file",1,-,"$my_date";" >> $MOLE_RC
  fi
else
	"$edit" "$dir/$file"
	exit 0
fi
	"$edit" "$dir/$file"

# 	latest_line=$(grep -Eo "[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}-[0-9]{2}-[0-9]{2}" $MOLE_RC | sort -r | head -n 1)
#	echo $latest_line
#	latest_line=$(echo "${latest_line%%\[$art]}")
#	latest_line=$(grep -En "$latest_line" $MOLE_RC | sed 's/\([0-9]*\):.*/\1/'  )
# 	echo $latest_line
#	
#	awk -F',' -v date="2023-03-03;$" '$5 < date {print $1"/"$2}' $MOLE_RC | sort -r | head -n 1 | tail -n 1

  

  

