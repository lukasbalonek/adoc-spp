#!/bin/bash

# this tool version
VERSION=1.3

# where script and it's files are located
install_dir=/usr/local/adoc-spp

# default values
toc_title=NAVIGATION
toc=left
favicon=media/favicon.png
media_dir=media
unset footer

# functions
get_help() {

  echo -e "\e[1m$(basename $0) ${VERSION}\e[m"
  echo -e "This script copies \$PWD content to target directory and converts .adoc files to .html's."
  echo -e "\nIf you want to exclude some files from copying, use file named \e[1m.adoc_exclude\e[m."
  echo -e "TIP: If you run this script without \e[1m.adoc_exclude\e[m, default one will be generated in \$PWD\n"
  echo -e "\e[1mBasic usage: \e[madoc-spp --dir=<destination directory (like public)>"
  echo -e "\e[1mAdditional options:\e[m"
  echo -e "--footer => Enables footer generation with 'Last updated YYYY-MM-DD HH-MM-SS timezone' information"
  echo -e "--toc-title=<optional Table Of Contents title (default is 'NAVIGATION')"
  echo -e "--favicon=<path to page favicon> (default is ${favicon}"
  echo -e "--toc=<where Table Of Contents should be>, by default \e[1mleft\e[m is used. For avaible options, visit \e[34mhttps://docs.asciidoctor.org/asciidoc/latest/toc/position/\e[m"
  echo -e "--media-dir=<global variable here media are stored> (default is 'media')"

}

# get script params
for arg in $@; do
	case $arg in
	--help)
	  get_help
          exit 0
	;;
	--dir=*)
          dest_dir=$(echo $arg | cut -d "=" -f2)
	;;
        --footer)
          footer=true
        ;;
        --toc-title=*)
          toc_title=$(echo $arg | cut -d "=" -f2)
        ;;
        --favicon=*)
          favicon=$(echo $arg | cut -d "=" -f2)
        ;;
        --toc=*)
          toc=$(echo $arg | cut -d "=" -f2)
        ;;
        --media-dir=*)
          media_dir=$(echo $arg | cut -d "=" -f2)
        ;;
	*)
          echo -e "\e[31mWrong usage for $(basename $0) script ! \n\e[m"
          get_help
          exit 42
	;;
  esac
done

# welcome message
echo -e "\e[32mRunning \e[1madoc-spp\e[m with options \e[1m$@\e[m ...\e[m"

# create destination directory
mkdir -p ${dest_dir}

# if there is folder media, copy to destination root
if [[ -d media ]]; then
  echo -e "\e[33mCopying media dir.\e[m"
  cp -rfv media ${dest_dir}/
else
  echo -e "\e[31mWarning: directory media/ not present !"
fi

# copy files for build
## insert default .adoc_exclude to .adoc_exclude
if [[ -f .adoc_exclude ]]; then
  echo -e "\e[33mUsing already present .adoc_exclude.\e[m"
  rm_exclude=0
else
  echo -e "\e[33mUsing default .adoc_exclude.\e[m"
  cp -fv ${install_dir}/.adoc_exclude .adoc_exclude
  rm_exclude=1
fi

## copy docinfo.html
echo -e "\e[33mCopying docinfo.html (page style).\e[m"
cp -fv ${install_dir}/docinfo.html .

# copy current dir to destination
echo -e "\e[33mSynchronizing current directory to ${dest_dir} ...\e[m"
rsync --links -av --quiet --exclude-from=.adoc_exclude . ${dest_dir}

# copy scripts
echo -e "\e[33mCopying scripts\e[m"
mkdir -p ${dest_dir}/scripts
cp -rfv ${install_dir}/scripts/. ${dest_dir}/scripts/

# find all .adoc(s)
adocs=$(find $dest_dir -mindepth 1 -type f -name '*.adoc' -exec bash -c "ls {}" \;)

# generate HTML(s)
echo -e "\e[33mGenerating into directory:\e[m ${dest_dir}"

for doc in ${adocs}; do
echo -e "\e[33mProcessing:\e[m ${doc}"
asciidoctor \
--backend html \
--base-dir . \
-a media-dir=${media_dir} \
-a l_icon="60,60" \
-a m_icon="30,30" \
-a s_icon="20,20" \
-a docinfo=shared \
-a favicon=${favicon} \
-a toc=${toc} \
-a toc-title=${toc_title} \
-a toclevels=5 \
-a icons=font \
$(if [[ -z ${footer} ]]; then echo -n "-a nofooter"; fi) \
${doc} && rm -f ${doc}
done

# remove temporary files
echo -e "\e[33mRemoving temporary files\e[m"
rm -fv \
${dest_dir}/docinfo.html \
${dest_dir}/.adoc_exclude \
docinfo.html
if [[ ${rm_exclude} -eq 1 ]]; then rm -fv .adoc_exclude; fi

echo -e "\e[32mDone. You can upload directory ${dest_dir} to your webserver now.\e[m"
