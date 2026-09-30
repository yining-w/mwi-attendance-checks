*==============================================================================*
*! Attendance Study
*! Ojective: Check data quality
*! Date created: 24/09/2026
*! Last modified: 28/09/2026
*==============================================================================*
** CHECKS:
* 1. Which teachers did not consent, which schools do we need to follow up with?
* 2. Which stream per standard was randomized? Which of them are in the treatment arm?
* 3. Issues to flag (registry from last year, or weather related)
* 4. Quality of photos (manual check)
*==============================================================================*

qui {
	
	** User change parameters 
	global dateofanalysis 290926 // update twice a week. Remember that 1110 was the "test" day data.
	global dateofdata "24sep2026"
	
	* User update here after manually checking quality issues
	local qualityissues "503173: STD2_A-P2 | 505237: STD2*,3*,4" // (290926)
	//local qualityissues "500233: STD2_A-P2;STD2-A-P3 | 505348: STD3-A-P1" (240926)

	// flag here if any photos could be improved for next time
	global overwriteimgs = 0  // turn to 0 if we don't want to over write the folder of images
	use "$raw\Baseline/$date\data_labelled baseline attandance form.dta", clear // baseline_attendance_form
	gen emisnumber = emis 
	merge 1:1 emisnumber using "${ref}/2. Randomization/randomization_schools_2treatments_emis.dta", nogen keep(matched) keepusing(treatment digitization)

	* Keep date of new data
	** YW: Will add this once we have the next round
	keep if survey_date >= td(${dateofdata})
	
	log using "$raw\Baseline/$date/summary_$date.log", replace
	// create a dummy for counts 
	gen dummy = 1

	* How many schools visited, by date
	noi di "** Summary **"
	noi di "How many schools visited in the latest sample"
	noi tabstat dummy,stat(count) by(survey_date)
	
	noi di "Enumerators / EMIS"
	noi li enumerator emis
	
	*********************************
	** 1. Headteachers consent     **
	*********************************
	noi di "** 1. Headteachers count **"
	// Flag any cases where the headteacher didnt give consent as we need to follow up/
	cap assert ht_consent == 1
	if _rc != 0 {
	noi di "Non-consenting cases:"
	noi list ht_consent emis if ht_consent == 2, compress 
	} 
	else {
		noi di "- All respondents consented in this round of collection"
	}

	// Flag cases of non-headteacher respondents
	cap assert respondent_role ==1
	if _rc != 0 {
		noi di ""
	noi di "- Non-headteacher respondents, to follow up by phone:"
	noi list emis respondent_role if respondent_role != 1, compress
	}
	else {
		noi di "- All respondents were headteachers in this round of collection"
	}

	*********************************
	** 2. Randomization            **
	*********************************
	forval n =1/4 {
		// How many classrooms are in each standard. 
		clonevar count_std`n' = num_std`n'
		// Which is the randomly selected classroom
		clonevar std`n'_selected_stream = std`n'_selected
	}

	** Check that if register is old, it is not selected for randomization 
	* This means that in any instance where all the available streams are not 'None', 
	* register_year_[n] should != 2
	destring std*_has_complete std*_has_partial, replace
	
	forval n = 1/4 {
			noi di ""
		noi di "- Schools that had completed or partial registries, but the selected stream from Standard `n' was from the previous year:"
		noi list emis if (std`n'_has_complete > 0 | std`n'_has_partial > 0) & register_year_`n' == 2, compress

		}
	
	noi di "Check if assigned treatment and SurveyCTO coding are consistent"
	noi di emis treatment sms_reminder_status digitization
	*********************************
	** 3. Status of the registries **
	*********************************
	/* Some cleaning notes:
		
	*** STATUS OF REGISTRY PER STREAM **
	 (1) std[x]_status_[n] and 
	 (2) std[x]_idx[n]_status represent the same things, 
	 where:
	 [x] = 1 to 4 (grades), and 
	 [n] = 1 to 26 (possible streams)
	 
	 *idx* is string version, and the number of variables created for std[x]_status_[n]
	 is based on the maximum number of classrooms across schools 
	 (eg, if the most number of classrooms within std1 across recorded schools 
	  is 4, then there will be 4 std[x]_status_[n] variables)
	 
	 ** CORRESPONDING STREAM OF THE GIVEN STATUS**
	 (1) std[x]_cur_letter_[n]
	 (2) std[x]_idx[n]_letter
	 are identical variables that identifies classroom stream [n] in letters 
	*/
		 
	* First, identify the streams consistently 
	forval n = 1/4 { // 4 standards
		* Restart the streams per standard
		local streamno = 1
		
		* Letter-ify the vars for easy tagging
		foreach l in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z {
			* The max variables = max number of classrooms cases 
			* (We can just focus on cleaning this one)
			* because we don't need both
			cap ren (std`n'_status_`streamno' std`n'_cur_letter_`streamno') ///
			(std`n'_status_`l' std`n'_cur_letter_`l')

			* Next corresponding letter 
			local streamno = `streamno' +1
		}
	 }
	
	* Get the status of the selected stream 
	lab def statuses 1 "Complete" 2 "Partial" 0 "None"
	forval n = 1/4 {
		gen std`n'_other_status = 0
		gen std`n'_selected_status = .

		foreach l in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z {
				
			** get status of the selected stream
			cap replace std`n'_selected_status = std`n'_status_`l' 	if std`n'_cur_letter_`l' != "" &  std`n'_selected == std`n'_cur_letter_`l' & std`n'_selected_status == .

			* whether non-selected streams had partial or unavailable statuses
			cap replace std`n'_other_status = 1 if std`n'_status_`l' != 1

			} // next stream 
		lab val std`n'_selected_status statuses
		lab val std`n'_other_status statuses

	}  // next std

	noi di "** 2. Randomization **"
	noi di "Registry statuses of selected streams"
	noi list emis sms_reminder_status std*_selected_stream std*_selected_status, compress

	// Create variable regarding they are using new or old registries. Check the "Other comments" variable to identify this.
	/* YW - Comments don't mention whether 'last year's register is for the whole school or select classrooms  
	* If uses 'old' registry, should this be treated as 'unavailable' in the status 
	* implications on randomization of the classroom stream
	// Old/new registry
	** Should we actually indicate whether this is the case for all streams or just a few,
	* if the latter, we indicate which stream in the comments (or can we retro-check this 
	* from the photos based on the date?)
	*/
	* For now this is a manual note 'FLAG'
	//local toflag "505638 500076 505348" // 240926
	local toflag "503617 501699 503173" // 290926

	gen flag = 0
	foreach e in `toflag' {
		replace flag = 1 if emis == `e'
	}
	
	** Which EMISes have old registries
	gen oldreg = inlist(emis, 505638,500076)
	gen oldreg_stds = "All" if emis== 505638
	replace oldreg_stds = "2;3" if emis== 500076 // to confirm
	

	forval n =1/4 {
		replace oldreg = 1 if register_year_`n'==2
		replace oldreg_stds = "`n'" if register_year_`n'==2 & oldreg_stds == ""
		replace oldreg_stds = oldreg_stds + ";" + "`n'" if register_year_`n'==2 & oldreg_stds != ""

	}
	
	noi di "** 3. Schools to flag for later **"	
	noi di "Issues related to weather conditions"
	noi list emis rain_access
	noi di "Other Issues flagged"
	noi list emis other_comments if flag == 1
	*************************************
	** 4. Quality of the photos  [x] [n]*
	** Organize and Rename Photos       *
	*************************************

	* first check that the EMIS filename saved is consistent with recorded emis
	* (so that we are recalling the correspondent EMIS photo file)
	* Note that the scanned PDF versions are already collapsed 
	* Number of [n] variables correspond to max number of pics taken
	* photo_page_num_[x]_[n]: page number of photo (n)
	* photo_emis_[x]_[n]: EMIS number of photo
	* photo_standard_[x]_[n]: Standard (1 to 4)
	* photo_stream_[x]_[n]: Correspondent stream of photo 
	* photo_id_[x]_[n]: Photo unique id 
	* photo_image_[x]_[n]: saved filename (image)
	noi di "** 4. Photo checks **"
	

	* First check: Stream of photo taken is the same as the selected stream 
	forval i = 1/4 {
		cap assert std`i'_selected == photo_stream_`i'_1 // only page1, schools have different pages available
		if _rc != 0 {
			noi di "CHECK: Standard `i'"
			li emis std`i'_selected photo_stream_`i'_1 if std`i'_selected != photo_stream_`i'_1
		}
	}

	* Check 3: check variables where selected registry status is 'complete' or 'partial' that the photo variable is not blank

	noi li emis std1_selected_status if inlist(std1_selected_status,1,2) & photo_image_1_1 == ""
	


	// CHECK 4 - CLEANING FOR MANUAL STEP: ORGANIZE PHOTOS INTO CORRESPONDING EMISES
	* (HOW IS THE PHOTO QUALITY?)
	** Updated after manual checking part ** 
	noi di "Photo quality concerns: `qualityissues'"
	
	log close 

	if ${overwriteimgs} == 1 {
	* The rest of this code simply reorganizes the raw photo files
	* Check file path exists in folder for corresponding variables 
	local tempdir "${raw}/Baseline/${date}/register_scans"
	local files : dir "`tempdir'/media" files "*.jpg" // YW: For next check, check that images files are still consistently saved as .png
	di `"`files'"'


	* Create a copy that we can rename for easy checks
	cap mkdir "`tempdir'/media_renamed"
	local files2del : dir "`tempdir'/media_renamed" files "*.jpg" // YW: For next check, check that images files are still consistently saved as .jpg

	* Delete any old copies 
	cap foreach f in `files2del' {
		erase "`tempdir'/media_renamed/`f'"
	}
	
	* Create new copy (this ensures we will always have an untouched original)
	foreach file in `files' {
		copy "`tempdir'/media/`file'" "`tempdir'/media_renamed/`file'"
	} 
	
	*some cleaning for matching 
	foreach var of varlist photo_image* {
		replace `var' = subinstr(`var', "media\","",.)
	}
	
	* now do the rename
	foreach allfiles of varlist photo_image_* {
		local toextract "`allfiles'"
		* Get the suffix of the loop (stream + page number)
		local savesuffix = substr("`toextract'", 13,.)
		noi di "Standard / Page `savesuffix'"
		
		* Rename per emis 
		levelsof `allfiles', local(filename) clean 
		foreach file in `filename' {
			levelsof photo_id_`savesuffix' if photo_image_`savesuffix'=="`file'", local(savename) clean 
			noi di "Renaming `file' to `savename'.."
			
			copy "`tempdir'/media_renamed/`file'" "$raw/Baseline/${date}/register_scans/media_renamed/`savename'.jpg"
			erase "`tempdir'/media_renamed/`file'"
		}
	}
	
	* Erase the registries that were not collected in this round
	local files : dir "`tempdir'/media" files "*.jpg" // YW: For next check, check that images files are still consistently saved as .png
	di `"`files'"'
	local files2del : dir "`tempdir'/media_renamed" files "*.jpg" // YW: For next check, check that images files are still consistently saved as .jpg

	* Delete any old copies 
	cap foreach f in `files2del' {
		erase "`tempdir'/media_renamed/`f'"
	}
	
	local tempdir "${raw}/Baseline/${date}/register_scans"

	* Now move to each EMIS folder 
	levelsof emis, local(schcodes)
	foreach sch in `schcodes' {
		forval s =1/4 {
		mvfiles, infolder("`tempdir'/media_renamed") outfolder("`tempdir'/media_renamed/`sch'") match("`sch'*") makedirs erase
	}
		}
		

	*********************************
	** 5. Keep key variables       **
	*********************************
	gen dateclean = ${date}
	local keepvars "survey_date emis district zone sms_reminder_status ht_consent respondent_role respondent_role_other num_std* std*_selected_status std*_other_status *selected_stream* flag other_comments photo_taken_* school_gps* oldreg oldreg_stds dateclean"
	keep `keepvars'
	order `keepvars'

	* beautify via lab var
	lab var sms_reminder_status "School assigned to receive SMS reminders"
	forval s = 1/4 {
		lab var std`s'_selected_status "Registry completion status of selected stream, Standard `s' (only partial or completed)"
		lab var std`s'_other_status "Whether non-selected stream has a different completion status, Standard `s'"
		lab var std`s'_selected_stream "Class letter of selected stream, Standard `s'"

	}
	lab var flag "Manual flag for checks"
	lab var dateclean "Date data was saved"
	
	save "$raw\Baseline/$date\baseline_attendance_CLEAN", replace
	}
} // end qui

