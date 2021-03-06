#!/bin/bash

# OpenEyes
# 
# (C) Moorfields Eye Hospital NHS Foundation Trust, 2008-2011
# (C) OpenEyes Foundation, 2011-2012
# This file is part of OpenEyes.
# OpenEyes is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.
# OpenEyes is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
# You should have received a copy of the GNU General Public License along with OpenEyes in a file titled COPYING. If not, see <http://www.gnu.org/licenses/>.
# 
# Utility script to create and copy ESB files to Mirth.

if [ ! -d $OE_INSTALL_SCRIPTS_DIR ]
then
	echo "Expected \$OE_INSTALL_SCRIPTS_DIR to be a directory;"
	echo "Set it correctly by calling"
	echo "  export OE_INSTALL_SCRIPTS_DIR [path]"
	echo "from your current shell, where [path] is the full path"
	echo "to the installation scripts directory."
	exit 1
fi

. $OE_INSTALL_SCRIPTS_DIR/base.sh
. $OE_INSTALL_SCRIPTS_DIR/esb/mirth/mirth-install.properties

# Patient ID, or hospital number
PID=1000001
# Name of the patient to include in certain files
GIVEN_NAME=Chey
# Family name of patient
FAMILY_NAME=Close

# Pause to give the ESB time to process files? Set this to 0 if not:
ESB_STEREO_SLEEP=5
# Pause between copying XML and (then) TIFF files? Set to 0 for no pause:
ESB_VFA_SLEEP=10

# Template files - these are used and processed in to a separate directory
TEMPLATE_STEREO_DIR=$OE_INSTALL_SCRIPTS_DIR/dev/esb-data/kowa-stereo
TEMPLATE_VFA_DIR=$OE_INSTALL_SCRIPTS_DIR/dev/esb-data/zeiss-vfa

# Where template data, after processing, os written to
SAMPLE_STEREO_DIR=$OE_INSTALL_SCRIPTS_DIR/dev/esb-data/sample-stereo
SAMPLE_VFA_DIR=$OE_INSTALL_SCRIPTS_DIR/dev/esb-data/sample-vfa

# 
# If the specified time is greater than 0, sleep for that many seconds.
# 
# $1 - the sleep time
# 
do_sleep() {
	SLEEP_TIME=$1;	
	if [ $SLEEP_TIME -gt 0 ]
	then
		log "Sleeping for $SLEEP_TIME second(s) before copying more files..."
		sleep $SLEEP_TIME
	fi
}

# 
# Copy sample data to the ESB.
# 
copy_sample_data() {
	if [ -d $SAMPLE_STEREO_DIR ]
	then
		for file in `ls $SAMPLE_STEREO_DIR/*.jpg`
		do
			cp `dirname $file`/`basename $file .jpg`.txt $OE_STEREO_TEXT_IN
			report_success $? "Copied `dirname $file`/`basename $file .jpg`.txt to $OE_VFA_TEXT_IN"
			do_sleep $ESB_STEREO_SLEEP
			cp $file $OE_STEREO_IMAGES_IN
			report_success $? "Copied $file to $OE_STEREO_IMAGES_IN"
		done
	fi
	if [ -d $SAMPLE_VFA_DIR ]
	then
		for file in `ls -v $SAMPLE_VFA_DIR/*.tif`
		do
			cp `dirname $file`/`basename $file .tif`.xml $OE_VFA_TEXT_IN
			report_success $? "Copied `dirname $file`/`basename $file .tif`.xml to $OE_VFA_TEXT_IN"
			do_sleep $ESB_VFA_SLEEP
			cp $file $OE_VFA_IMAGES_IN
			report_success $? "Copied $file to $OE_VFA_IMAGES_IN"
		done
	fi
}

# 
# Remove data produced from creating sample data
# 
clean_sample_data() {
	if [ -d $SAMPLE_STEREO_DIR ]
	then
		rm -rf $SAMPLE_STEREO_DIR
		log "Removed $SAMPLE_STEREO_DIR"
	fi
	if [ -d $SAMPLE_VFA_DIR ]
	then
		rm -rf $SAMPLE_VFA_DIR
		log "Removed $SAMPLE_VFA_DIR"
	fi
}

# 
# Generate sample data for the Kowa stereo images.
# 
generate_sample_stereo_data() {
	mkdir -p $SAMPLE_STEREO_DIR;
	for file in `ls $TEMPLATE_STEREO_DIR/[1-2].jpg`; do
		SIDE='R'
		cp $file "$SAMPLE_STEREO_DIR/ID$PID-`basename $file .jpg`.jpg"
		report_success $? "Created $SAMPLE_STEREO_DIR/ID$PID-`basename $file .jpg`.jpg"
		PHOTO_ID=`basename $file .jpg`;
		cat $TEMPLATE_STEREO_DIR/template.txt | sed s/'_SIDE_'/$SIDE/ | sed s/'_PHOTOID_'/$PHOTO_ID/ | sed s/'_FAMILY_NAME_'/$FAMILY_NAME/ | sed s/'_GIVEN_NAME_'/$GIVEN_NAME/ | sed s/'_PID_'/$PID/ >> "$SAMPLE_STEREO_DIR/ID$PID-$PHOTO_ID.txt"
		report_success $? "Created $SAMPLE_STEREO_DIR/ID$PID-$PHOTO_ID.txt"
	done

	for file in `ls $TEMPLATE_STEREO_DIR/[3-4].jpg`; do
		SIDE='L'
		cp $file "$SAMPLE_STEREO_DIR/ID$PID-`basename $file .jpg`.jpg"
		report_success $? "Created $SAMPLE_STEREO_DIR/ID$PID-`basename $file .jpg`.jpg"
		PHOTO_ID=`basename $file .jpg`;
		cat $TEMPLATE_STEREO_DIR/template.txt | sed s/'_SIDE_'/$SIDE/ | sed s/'_PHOTOID_'/$PHOTO_ID/ | sed s/'_FAMILY_NAME_'/$FAMILY_NAME/ | sed s/'_GIVEN_NAME_'/$GIVEN_NAME/ | sed s/'_PID_'/$PID/ >> "$SAMPLE_STEREO_DIR/ID$PID-$PHOTO_ID.txt"
		report_success $? "Created $SAMPLE_STEREO_DIR/ID$PID-$PHOTO_ID.txt"
	done

}

# 
# Generate VFA data in $SAMPLE_VFA_DIR; creates 11
# files each for each eye, each for an image and XML
# configuration file (for a total of 44 files).
# 
# Note the XML files relate directly to the image file,
# and the XML file MUST be processed BEFORE the image
# file is processed.
#
generate_sample_vfa_data() {
	
	TMP_VFA_DIR=$SAMPLE_VFA_DIR/tmp
	mkdir -p $SAMPLE_VFA_DIR/tmp

	# Create reverse images for the left eye:
	for file in `ls -r $TEMPLATE_VFA_DIR/*.jpg`; do convert -geometry 696x710 -black-threshold 75% -flop $file $TMP_VFA_DIR/left-`basename $file .jpg`.tif; log "Created $TMP_VFA_DIR/left-`basename $file .jpg`.tif"; done
	# Create non reversed TIFF images for the right eye:
	for file in `ls -r $TEMPLATE_VFA_DIR/*.jpg`; do convert -geometry 696x710 -black-threshold 75% $file $TMP_VFA_DIR/right-`basename $file .jpg`.tif; log "Created $TMP_VFA_DIR/right-`basename $file .jpg`.tif"; done

	# for file in *.jpg; do convert -black-threshold 0 -geometry 834x938 $file tif/`basename $file .jpg`.tif; done

	for file in `ls -r $TMP_VFA_DIR/*.tif`;
	do 
		composite -geometry +1351+640 $file $TEMPLATE_VFA_DIR/main_image_1.tif $TMP_VFA_DIR/TEST_`basename $file .tif`.jpg;
		report_success $? "Composed $TEMPLATE_VFA_DIR/main_image_1.tif and $TMP_VFA_DIR/TEST_`basename $file .tif`.jpg to make: $TMP_VFA_DIR/TEST_`basename $file .tif`.jpg"
		convert $TMP_VFA_DIR/TEST_`basename $file .tif`.jpg $SAMPLE_VFA_DIR/TEST_`basename $file`;
		report_success $? "Created $SAMPLE_VFA_DIR/TEST_`basename $file`"
		rm $TMP_VFA_DIR/TEST_`basename $file .tif`.jpg
	done

	rm $TMP_VFA_DIR/left-hfa*.tif
	rm $TMP_VFA_DIR/right-hfa*.tif

	for file in `ls -r $SAMPLE_VFA_DIR/TEST_left*.tif`;
	do
		XML_SHORT_FILE=$SAMPLE_VFA_DIR/`basename $file .tif`.xml
		cp $TEMPLATE_VFA_DIR/Example_HFA_short.xml $XML_SHORT_FILE;
		sed -i s/_FAMILY_NAME/$FAMILY_NAME/ $XML_SHORT_FILE
		sed -i s/_GIVEN_NAME/$GIVEN_NAME/ $XML_SHORT_FILE
		sed -i s/_PATIENT_ID/$PID/ $XML_SHORT_FILE
		sed -i s/_FILE_REFERENCE/`basename $file`/ $XML_SHORT_FILE
		sed -i s/_LATERALITY/L/ $XML_SHORT_FILE
		report_success $? "Created $XML_SHORT_FILE"
	done;
	for file in `ls -r $SAMPLE_VFA_DIR/TEST_right*.tif`;
	do
		XML_SHORT_FILE=$SAMPLE_VFA_DIR/`basename $file .tif`.xml
		cp $TEMPLATE_VFA_DIR/Example_HFA_short.xml $XML_SHORT_FILE;
		sed -i s/_FAMILY_NAME/$FAMILY_NAME/ $XML_SHORT_FILE
		sed -i s/_GIVEN_NAME/$GIVEN_NAME/ $XML_SHORT_FILE
		sed -i s/_PATIENT_ID/$PID/ $XML_SHORT_FILE
		sed -i s/_FILE_REFERENCE/`basename $file`/ $XML_SHORT_FILE
		sed -i s/_LATERALITY/R/ $XML_SHORT_FILE
		report_success $? "Created $XML_SHORT_FILE"
	done;
}

# 
# Prints help information.
# 
print_help() {
  echo "Utilities for creating ESB files from basic templates,"
  echo "based on given patient data. By default, PID $PID,"
  echo "forename '$GIVEN_NAME' and surname '$FAMILY_NAME' are used."
  echo ""
  echo "Currently, only Kowa Stereo images and Zeiss VFA images"
  echo "are catered for, along with text files (.txt and .xml"
  echo "respectively) that are normally associated with each"
  echo "image produced."
  echo ""
  echo "Configuration options should be provided first, followed"
  echo "by installation targets which are executed in the order"
  echo "they are specified."
  echo ""
  echo "Configuration options:"
  echo ""
  echo "  -H <hos_num>: specify hospital number (default $PID)."
  echo "  -G <given_name>: specify forename/given name (default $GIVEN_NAME)."
  echo "  -F <family_name>: specify family name (default $FAMILY_NAME)."
  echo ""
  echo "Script targets:"
  echo ""
  echo "  -s: Generate Kowa stereo images and text files."
  echo "      Uses: -H, -G, -F"
  echo "  -v: Generate Zeiss VFA images and XML files."
  echo "      Uses: -H, -G, -F"
  echo "  -c: Copy all files to the relevant ESB directories."
  echo "      Depends: -s or -v."
  echo "  -x: Remove (local) sample data directories, generated from"
  echo "      invoking one of the targets to generate file"
  echo "      data (-s, -v)"
  echo "  -h: Print this help then quit."
}

# 
# Main arg loop. Lower case letters are for commands to issue; upper-case
# letters are for configuration properties (e.g. -X <value>). Lower-case
# commands take no arguments; all upper-case configuration values should
# be specified first. The order of commands is the order they are
# executed in; so specifying -b -n will back up the site and database and
# then nuke the DB and sources.
# 
# Inspired by http://wiki.bash-hackers.org/howto/getopts_tutorial
# 
while getopts ":csvxhH:G:F:" opt; do
  case $opt in
    H)
      log "Patient ID/hospital number specified: $OPTARG" >&2
      PID="$OPTARG"
      ;;
    F)
      log "Given name specified: $OPTARG" >&2
      GIVEN_NAME="$OPTARG"
      ;;
    G)
      log "Family name specified: $OPTARG" >&2
      FAMILY_NAME="$OPTARG"
      ;;
    x)
      clean_sample_data
      ;;
    c)
      copy_sample_data
      ;;
    s)
      generate_sample_stereo_data
      ;;
    v)
      generate_sample_vfa_data
      ;;
    h)
      print_help
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      ;;
  esac
done
