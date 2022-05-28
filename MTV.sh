#!/bin/bash

announce_url="http://url.here/"

#Temp path for several writes
Temp_path="/dev/shm/"

#Auto open the text files for copying info into MTV upon completion (0 = false; 1 = true)
Auto_open_after=0

#Where to save the final results
#(leave blank to have the only copy at Temp_path; Temp_path keeps a copy no matter what)
Save_path=""



if [ "$#" -eq 0 ]; then
	echo 'No file path entered'
	echo 'Usage: ./MTV.sh /path/to/file(s)'
	exit
fi
if [ ! -d "$1" ] && [ ! -f "$1" ]; then
	echo 'The video Directory/file path entered does not exist'
	exit
fi
if [ ! -d "${Temp_path}" ]; then
	echo "The Temporary directory stored in the script's variable 'Temp_path' doesn't exist:"
	echo "Temp_path=$Temp_path"
	echo "Edit the script to fix"
	exit
fi
if [ ! -d "${Save_path}" ] && [ ! -z "$Save_path" ]; then
        echo "The Save directory stored in the script's variable 'Save_path' doesn't exist:"
        echo "Save_path=$Save_path"
        echo "Edit the script to fix. Leave blank to not use it."
        exit
fi


#Script expects directories to have a trailing slash
if [ ! "${Temp_path: -1}" = '/' ]; then
Temp_path="$Temp_path/"
fi
if [ ! "${Save_path: -1}" = '/' ]  && [ ! -z "$Save_path" ]; then
Save_path="$Save_path/"
fi


#Get Title
upsies submit bhd "$1" --oti > "${Temp_path}start.txt"

	#Format title
#put the # of sound channels alongside audio codec
perl -pi -w -e 's/\s(\d\.\d)/$1/' "${Temp_path}start.txt"

#Replace Dobly Digital with AC3 (DDP should stay however)
perl -pi -w -e 's/DD(\d\.\d.*)/AC3.$1/' "${Temp_path}start.txt"

#replace spaces with periods
perl -pi -w -e 's/\s/\./g' "${Temp_path}start.txt"

#Commented: May be a moderator's preferance which is used for x264 & x265
#Change x265 to H.265
perl -pi -w -e 's/x265/H.265/g' "${Temp_path}start.txt"

#Change H.?264 to x264
#perl -pi -w -e 's/H.?264/x264/g' "${Temp_path}start.txt"

#reinsert end of line
perl -pi -w -e 's/\.$/\n/g' "${Temp_path}start.txt"

name="$( head -n 1 ${Temp_path}start.txt )"
working_path="${Temp_path}${name}/"


#Create directory for storage
if [ ! -d "${working_path}" ]; then
	mkdir "${working_path}"
fi

#From now on, all files are now inside of the torrent's directory for relavance
mv "${Temp_path}start.txt" "${working_path}"

#Make Description
upsies submit bb "$1" --only-description --screenshots 4 > "${working_path}info.txt"



#Check Scene
upsies scene-check "$1" > "${working_path}final.txt"
echo '-------------------' >> "${working_path}final.txt"

#Add Title
cat "${working_path}start.txt" >> "${working_path}final.txt"

	#Check if TV series (Else Movie)
	#Formatting Description for both
if grep -q '\[img=' "${working_path}info.txt"; then

mv "${working_path}info.txt" "${working_path}desc.txt"
#put mediainfo before TV-series info
perl -0777 -pi -w -e 's/([\s\S]+)(\[med[\s\S]+)/$2$1/g;' "${working_path}desc.txt"


#Delete a quote & insert screens + spoiler
perl -0777 -pi -w -e 's/([\s\S]+)\[quote\]([\s\S]+center\])([\s\S]+)(\[[\s\S]+)..quote./$1$2\[screens\]\n\[spoiler\]$3\[\/spoiler\]$4/g;' "${working_path}desc.txt"

        #Don't blame biggles for the my poor scripting
echo  '[align=right][size=1]Shared with [url=https://upsies.readthedocs.io]upsies[/url] & [url=https://github.com/Reverse256/GlueCodeUpsies]Glue Code[/url][/size][/align]' >> "${working_path}desc.txt"

else
#Create Movie Description


#mediainfo
echo '[mediainfo]' > "${working_path}desc.txt"
upsies mediainfo "$1" >> "${working_path}desc.txt"
echo '[/mediainfo]' >> "${working_path}desc.txt"

#Add Movie information
cat "${working_path}info.txt" >> "${working_path}desc.txt"


#Fix images formatting
	upsies submit bhd "$1" --od > "${working_path}images.txt"

        #Fix bBcode align & insert 'screens' 'spoiler'
        perl -pi -w -e 's/\[(center\])\n/\[align=$1\[screens\]\n\[spoiler\]/' "${working_path}images.txt"

        #Each image on its own line instead of double up
        perl -0777 -pi -w -e 's/(\s{3}|\n\n)/\n/g' "${working_path}images.txt"

        #Add /spoiler & Fix /align
        perl -pi -w -e 's/\[\/center/\[\/spoiler\]\[\/align/g' "${working_path}images.txt"

        #Fix align=right
        perl -pi -w -e 's/(right)/align=$1/' "${working_path}images.txt"

#todo
        #Don't blame biggles for the my poor scripting
        perl -pi -w -e 's/(\[\/size)\[\/right/ & [url=https://github.com/Reverse256/GlueCodeUpsies]Glue Code[/url]$1\[\/align/g' "${working_path}images.txt"

		cat "${working_path}images.txt" >> "${working_path}desc.txt"
fi


#Get Tags and format for UHDBits
upsies submit bb "$1" --ota >> "${working_path}final.txt"
perl -pi -w -e 's/,/ /g' "${working_path}final.txt"

#Get Poster url
upsies submit bb "$1" --op >> "${working_path}final.txt"

rm "${working_path}start.txt"
if [ -f "${working_path}images.txt" ]; then
	rm "${working_path}images.txt"
fi
if [ -f "${working_path}info.txt" ]; then
	rm "${working_path}info.txt"
fi

#Open 2 files for copying into MTV
if [ "$Auto_open_after" -eq 1 ]; then
	xdg-open "${working_path}final.txt"
	xdg-open "${working_path}desc.txt"
fi


#Create Torrent

###### Advantages Compare ##########
##old Method (upsies create-torrent)
# +Ignores .unwanted/ & .nfo, etc.
# +Nicer UI
# -Might create a >8MB piece torrent

##New Method (mktorrent)
# +Guarantee <=8MB pieces

#New Create Torrent technique
#Get the dir/file size in bytes
i="$(du -b -d 0 ${1} | cut -f -1)"

#convert the Byte file/dir size into its binary exponent (2^i) and round to a whole number
i=$(printf "%.0f\n" $(bc -l <<< "l(${i}) / l(2)"))

#Attempt to get close to 1024 pieces
i=$(bc -l <<< "${i}-10")

#Max piece size = 8MB
i=$((i<23?i:23))

#Min piece size = 32kB
i=$((i>15?i:15))

#Create torrent
mktorrent -l "${i}" -a "${announce_url}" -o "${working_path}${name}.torrent" "$1"


###########
#Old method - (adverse side-effct: it creates a .torrent file inside the current dir of the terminal)
#upsies torrent-create bb "$1" -c "${working_path}"

########For old method. Use at your own risk
#Remove all torrent files in your current directory (creaing a torrent file with upsies will put a .torrent file in your current dir)
#rm *.torrent
############


#Copy to the User's preferred location
if [ ! -z "$Save_path" ]; then
	cp -r "${working_path}" "${Save_path}"
	echo 'Compelete!'; echo Saved\ at:\ "${Save_path}${name}"; exit
fi

echo 'Complete!'; echo Saved\ at:\ "${working_path}"; exit
