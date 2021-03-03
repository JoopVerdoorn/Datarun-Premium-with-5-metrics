using Toybox.Math;
using Toybox.WatchUi as Ui;
class CiqView extends ExtramemView {  
	var mfillColour 						= Graphics.COLOR_LT_GRAY;
	var Averagepowerpersec 					= 0;
	var uBlackBackground 					= false;
	var uFTP								= 250;   
	var i 									= 0;
	var setPowerWarning 					= 0;
	var Garminfont = Ui.loadResource(Rez.Fonts.Garmin4);
	var Garminfontklein = Ui.loadResource(Rez.Fonts.Garmin1);
	var Power 								= [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    var uPowerTarget						= 225;
    var uOnlyPwrCorrFactor					= false;
    var uPwrTempcorrect 					= 0;
    var uPwrHumidcorrect 					= 0;
    var uPwrAlticorrect 					= 0; 
    var uFTPTemp							= 20;
    var uManTemp							= 20;
	var PwrCorrFactor							= 1;
    var uRealHumid 							= 40;
    var uFTPHumid 							= 70;
    var uRealAltitude 						= 2;
    var uFTPAltitude 						= 200;
    var workoutTarget 						;
    hidden var hasWorkoutStep 				= false;
    hidden var WorkoutStepLowBoundary		= 0;
    hidden var WorkoutStepHighBoundary		= 999;
    hidden var is32kBdevice					= false;
    var AveragePower						= 0;
    var WorkoutStepNr						= 0;
    var WorkoutStepDuration 				= 0; 
    var StartTimeNewStep					= 0;
    var StartDistanceNewStep				= 0;
    var RemainingWorkoutTime  				= 0;
    var RemainingWorkoutDistance			= 0;
    var WorkoutStepDurationType  			= 9;

            		            				
    function initialize() {
        ExtramemView.initialize();
		var mApp 		 = Application.getApp();
		uPowerZones		 = mApp.getProperty("pPowerZones");	
		PalPowerzones 	 = mApp.getProperty("p10Powerzones");
		uPower10Zones	 = mApp.getProperty("pPPPowerZones");
		uFTP		 	 = mApp.getProperty("pFTP");
		uPowerTarget	 = mApp.getProperty("pPowerTarget");
		uOnlyPwrCorrFactor= mApp.getProperty("pOnlyPwrCorrFactor");
		uPwrTempcorrect	 = mApp.getProperty("pPwrTempcorrect");
		uFTPTemp	 	 = mApp.getProperty("pFTPTemp");
		uManTemp	 	 = mApp.getProperty("pManTemp");
		uPwrHumidcorrect = mApp.getProperty("pPwrHumidcorrect");
		uRealHumid 		 = mApp.getProperty("pRealHumid");
    	uFTPHumid 		 = mApp.getProperty("pFTPHumid");
    	uPwrAlticorrect  = mApp.getProperty("pPwrAlticorrect");
    	uRealAltitude 	 = mApp.getProperty("pRealAltitude");
    	uFTPAltitude	 = mApp.getProperty("pFTPAltitude");
    	
    	uRealHumid = (uRealHumid != 0 ) ? uRealHumid : 1;
		uFTPHumid = (uFTPHumid != 0 ) ? uFTPHumid : 1;
    	
    	if (utempunits == true ) {
			uFTPTemp = (uFTPTemp-32)/1.8;
			uManTemp = (uManTemp-32)/1.8;
		}
		
		i = 0;	
		for (i = 1; i < 11; ++i) {
			Power[i] = 0;
		}		
    }


    //! Calculations we need to do every second even when the data field is not visible
    function compute(info) {
        //! If enabled, switch the backlight on in order to make it stay on
        if (uBacklight) {
             Attention.backlight(true);
        }
		//! We only do some calculations if the timer is running
		if (mTimerRunning) {  
			jTimertime 		 = jTimertime + 1;
			//!Calculate lapheartrate
            mHeartrateTime	 = (info.currentHeartRate != null) ? mHeartrateTime+1 : mHeartrateTime;				
           	mElapsedHeartrate= (info.currentHeartRate != null) ? mElapsedHeartrate + info.currentHeartRate : mElapsedHeartrate;
           	
            //! Calculate temperature compensation, B-variables reference cell number from cells of conversion excelsheet  		
            var B6 = 22; 			//! is cell B6
            if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 0) {
            	PwrCorrFactor = 1;  //! no temperature compensation
            } else {
            	if (jTimertime < 300 and uPwrTempcorrect == 1 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 0) {
            		PwrCorrFactor = 1;  //! no temperature compensation
            	} else {
            		if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 0) {
            			uFTPTemp = 18;
            			B6 = 18;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
        	    		uFTPAltitude = 200;
            			uRealAltitude =	200;
            		} else if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 1) {
            			uFTPTemp = 18;
            			B6 = 18;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
    	        		uRealAltitude =	(info.altitude != null) ? info.altitude : 0;
            		} else if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 2) {
            			uFTPTemp = 18;
            			B6 = 18;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
            		} else if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 0) {
            			uFTPTemp = 18;
            			B6 = 18;  
        	    		uFTPAltitude = 200;
            			uRealAltitude =	200;
            		} else if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 1) {
            			uFTPTemp = 18;
            			B6 = 18;  
            			uRealAltitude =	(info.altitude != null) ? info.altitude : 0;
            		} else if (uPwrTempcorrect == 0 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 2) {
            			uFTPTemp = 18;
            			B6 = 18;  
            		} else if (uPwrTempcorrect == 1 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 0) {
            			B6 = (utempunits == false) ? tempeTemp : tempeTemp + utempcalibration/1.8 ;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
        	    		uFTPAltitude = 200;
            			uRealAltitude =	200;
            		} else if (uPwrTempcorrect == 1 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 1) {
            			B6 = (utempunits == false) ? tempeTemp : tempeTemp + utempcalibration/1.8 ;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
    	        		uRealAltitude =	(info.altitude != null) ? info.altitude : 0;
            		} else if (uPwrTempcorrect == 1 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 2) {
            			B6 = (utempunits == false) ? tempeTemp : tempeTemp + utempcalibration/1.8 ;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
            		} else if (uPwrTempcorrect == 1 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 0) {
            			B6 = (utempunits == false) ? tempeTemp : tempeTemp + utempcalibration/1.8 ;  
        	    		uFTPAltitude = 200;
            			uRealAltitude =	200;
            		} else if (uPwrTempcorrect == 1 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 1) {
            			B6 = (utempunits == false) ? tempeTemp : tempeTemp + utempcalibration/1.8 ;
            			uRealAltitude =	(info.altitude != null) ? info.altitude : 0;  
            		} else if (uPwrTempcorrect == 1 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 2) {
            			B6 = (utempunits == false) ? tempeTemp : tempeTemp + utempcalibration/1.8 ;  
            		} else if (uPwrTempcorrect == 2 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 0) {
            			B6 = uManTemp;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
        	    		uFTPAltitude = 200;
            			uRealAltitude =	200;
            		} else if (uPwrTempcorrect == 2 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 1) {
            			B6 = uManTemp;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
    	        		uRealAltitude =	(info.altitude != null) ? info.altitude : 0;
            		} else if (uPwrTempcorrect == 2 and uPwrHumidcorrect == 0 and uPwrAlticorrect == 2) {
            			B6 = uManTemp;  
	            		uFTPHumid = 70;
    	        		uRealHumid = 70;
            		} else if (uPwrTempcorrect == 2 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 0) {
            			B6 = uManTemp;  
        	    		uFTPAltitude = 200;
            			uRealAltitude =	200;
            		} else if (uPwrTempcorrect == 2 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 1) {
            			B6 = uManTemp;
            			uRealAltitude =	(info.altitude != null) ? info.altitude : 0;  
            		} else if (uPwrTempcorrect == 2 and uPwrHumidcorrect == 2 and uPwrAlticorrect == 2) {
            			B6 = uManTemp;  
            		}

					var B22 = 101325 * Math.pow((B6+273.15)/((B6+273.15)+(-0.0065 * uRealAltitude)) , ((9.80665 * 0.0289644) / (8.31432 * -0.0065))) * 0.00750062;
					var B23 = 101325 * Math.pow((uFTPTemp+273.15)/((uFTPTemp+273.15)+(-0.0065 * uFTPAltitude)) , ((9.80665 * 0.0289644) / (8.31432 * -0.0065))) * 0.00750062;
					var B24 = (-174.1448622 + 1.0899959 * B22 + -1.5119*0.001 * Math.pow(B22 , 2) + 0.72674 * Math.pow(10 , -6) * Math.pow(B22 , 3)) / 100;
					var B25 = (-174.1448622 + 1.0899959 * B23 + -1.5119*0.001 * Math.pow(B23 , 2) + 0.72674 * Math.pow(10 , -6) * Math.pow(B23 , 3)) / 100;
					var B36 = (257.14 * (Math.ln(Math.pow(2.718281828459, ((18.678-B6/234.5)*(B6/(257.14+B6))))*uRealHumid/100)) / (18.678-(Math.ln(Math.pow(2.718281828459, ((18.678-B6/234.5)*(B6/(257.14+B6))))*uRealHumid/100)))) * 1.8 + 32;
					var B37 = (257.14 * (Math.ln(Math.pow(2.718281828459, ((18.678-uFTPTemp/234.5)*(uFTPTemp/(257.14+uFTPTemp))))*uFTPHumid/100)) / (18.678-(Math.ln(Math.pow(2.718281828459, ((18.678-uFTPTemp/234.5)*(uFTPTemp/(257.14+uFTPTemp))))*uFTPHumid/100)))) * 1.8 + 32;
					var B38;
					var Btemp = B36+B6*1.8+32; 
					if ((Btemp) > 100) {
						B38 = 0.001341 * Math.pow((Btemp) , 2) - 0.249517 * Math.pow((Btemp) , 1) + 11.699986;   
					} else {
			    		B38 = 0;
					}	
					Btemp = B37+uFTPTemp*1.8+32;
					var B39;	
					if ((Btemp) > 100) {
						B39 = 0.001341 * Math.pow((Btemp) , 2) - 0.249517 * Math.pow((Btemp) , 1) + 11.699986;
					} else {
				    	B39 = 0;
					}      
					PwrCorrFactor = 1- (B24 - B25) - (B39-B38)/100;
				}
			}
           	
            //!Calculate lappower
            mPowerTime		 = (info.currentPower != null) ? mPowerTime+1 : mPowerTime;
            if (uOnlyPwrCorrFactor == false) {
            	runPower 		 = (info.currentPower != null) ? (info.currentPower+0.001)*PwrCorrFactor : 0;
            } else {
            	runPower 		 = (info.currentPower != null) ? info.currentPower : 0;
            }
			mElapsedPower    = mElapsedPower + runPower;
				 			             
        }
	}

    //! Store last lap quantities and set lap markers after a lap
    function onTimerLap() {
		Lapaction ();
	}

	//! Store last lap quantities and set lap markers after a step within a structured workout
	function onWorkoutStepComplete() {
	var info = Activity.getActivityInfo();
		Lapaction ();
		++WorkoutStepNr;		
		StartTimeNewStep = jTimertime;
        StartDistanceNewStep = (info.elapsedDistance != null) ? info.elapsedDistance / unitD : 0;
	}

	function onWorkoutStarted() {
        var info = Activity.getActivityInfo();
        WorkoutStepNr = 1;
        StartTimeNewStep = jTimertime;
        StartDistanceNewStep = (info.elapsedDistance != null) ? info.elapsedDistance / unitD : 0;
    }

	function onUpdate(dc) {
		//! call the parent onUpdate to do the base logic
		ExtramemView.onUpdate(dc);
		var info = Activity.getActivityInfo();		
		
		//!Calculate 10sec averaged power
        var AveragePower5sec  	 			= 0;
        var AveragePower10sec  	 			= 0;
        var currentPowertest				= 0;
		if (info.currentSpeed != null) {
        	currentPowertest = runPower; 
        }
        if (currentPowertest > 0) {
            if (currentPowertest > 0) {
        		Power[10] 								= Power[9];
        		Power[9] 								= Power[8];
        		Power[8] 								= Power[7];
        		Power[7] 								= Power[6];
        		Power[6] 								= Power[5];
        		Power[5] 								= Power[4];
        		Power[4] 								= Power[3];
        		Power[3] 								= Power[2];
        		Power[2] 								= Power[1];
				if (info.currentPower != null) {
        			Power[1]								= runPower; 
        		} else {
        			Power[1]								= 0;
				}        		
				AveragePower10sec	= (Power1+Power[2]+Power[3]+Power[4]+Power[5]+Power[6]+Power[7]+Power[8]+Power[9]+Power[10])/10;
				AveragePower5sec	= (Power[1]+Power[2]+Power[3]+Power[4]+Power[5])/5;
				AveragePower3sec	= (Power[1]+Power[2]+Power[3])/3;
			}
 		}

		var ElapsedDistance = (info.elapsedDistance != null) ? info.elapsedDistance / unitD : 0;
		if (Activity has :getCurrentWorkoutStep) {
			workoutTarget = Toybox.Activity.getCurrentWorkoutStep();
			hasWorkoutStep = true;
			WorkoutStepLowBoundary = (workoutTarget != null) ? (workoutTarget.step.targetValueLow.toNumber() - 1000) : 0;
			WorkoutStepHighBoundary = (workoutTarget != null) ? (workoutTarget.step.targetValueHigh.toNumber() - 1000) : 999;
			WorkoutStepLowBoundary = (uOnlyPwrCorrFactor == false) ? WorkoutStepLowBoundary : WorkoutStepLowBoundary/PwrCorrFactor;
			WorkoutStepHighBoundary = (uOnlyPwrCorrFactor == false) ? WorkoutStepHighBoundary : WorkoutStepHighBoundary/PwrCorrFactor;
			WorkoutStepDurationType = (workoutTarget != null) ? workoutTarget.step.durationType.toNumber() : 0;

			if (workoutTarget != null) {
				WorkoutStepDuration = (workoutTarget.step.durationValue != null) ? workoutTarget.step.durationValue.toNumber() : 9999999;
			} else {
				WorkoutStepDuration = 0;
			}

			if (WorkoutStepDurationType == 0) {
				RemainingWorkoutTime = WorkoutStepDuration - (jTimertime - StartTimeNewStep);
			} else if (WorkoutStepDurationType == 1) {
				RemainingWorkoutDistance = WorkoutStepDuration/unitD - (ElapsedDistance - StartDistanceNewStep);
			} else if (WorkoutStepDuration == 9999999) {
				RemainingWorkoutDistance = 0;
			}
			
		} else {
			hasWorkoutStep = false;
			WorkoutStepLowBoundary = 0;
			WorkoutStepHighBoundary = 999;
			RemainingWorkoutTime = 0;
			RemainingWorkoutDistance = 0;
		}
		
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
		
		AveragePower = (info.averagePower != null) ? info.averagePower : 0;
		
		i = 0; 
	    for (var i = 1; i < 6; ++i) {
	        if (metric[i] == 38) {
    	        fieldValue[i] =  runPower;     	        
        	    fieldLabel[i] = "Cur Pzone";
            	fieldFormat[i] = "1decimal";
            } else if (metric[i] == 99) {
    	        fieldValue[i] =  AveragePower3sec;     	        
        	    fieldLabel[i] = "3s P zone";
            	fieldFormat[i] = "1decimal";
            } else if (metric[i] == 100) {
    	        fieldValue[i] =  AveragePower5sec;     	        
        	    fieldLabel[i] = "5s P zone";
            	fieldFormat[i] = "1decimal"; 
            } else if (metric[i] == 101) {
    	        fieldValue[i] =  AveragePower10sec;     	        
        	    fieldLabel[i] = "10s P zone";
            	fieldFormat[i] = "1decimal";  
            } else if (metric[i] == 102) {
    	        fieldValue[i] =  LapPower;     	        
        	    fieldLabel[i] = "Lap Pzone";
            	fieldFormat[i] = "1decimal";  
            } else if (metric[i] == 103) {
    	        fieldValue[i] =  LastLapPower;     	        
        	    fieldLabel[i] = "LL Pzone";
            	fieldFormat[i] = "1decimal";
            } else if (metric[i] == 104) {
    	        fieldValue[i] =  (info.averagePower != null) ? info.averagePower : 0;     	        
        	    fieldLabel[i] = "Av Pzone";
            	fieldFormat[i] = "1decimal";           	          	
			} else if (metric[i] == 55) {   
            	if (info.currentSpeed == null or info.currentSpeed==0) {
            		fieldValue[i] = 0;
            	} else {
            		fieldValue[i] = (info.currentSpeed > 0.001) ? 100/info.currentSpeed : 0;
            	}
            	fieldLabel[i] = "s/100m";
        	    fieldFormat[i] = "1decimal";
        	} else if (metric[i] == 25) {
    	        fieldValue[i] = (LapPower != 0) ? mLapSpeed*60/LapPower : 0;
        	    fieldLabel[i] = "Lap EI";
            	fieldFormat[i] = "2decimal";
			} else if (metric[i] == 26) {
    	        fieldValue[i] = (LastLapPower != 0) ? mLastLapSpeed*60/LastLapPower : 0;
        	    fieldLabel[i] = "LL EI";
            	fieldFormat[i] = "2decimal";
			} else if (metric[i] == 27) {
	            fieldValue[i] = (info.averageSpeed != null and info.averagePower != null and info.averagePower != 0) ? info.averageSpeed*60/info.averagePower : 0;
    	        fieldLabel[i] = "Avg EI";
        	    fieldFormat[i] = "2decimal";
			} else if (metric[i] == 31) {
	            fieldValue[i] = (runPower != 0) ? Averagespeedinmper3sec*60/runPower : 0;
    	        fieldLabel[i] = "Cur EI";
        	    fieldFormat[i] = "2decimal";
        	} else if (metric[i] == 70) {
    	        fieldValue[i] = AveragePower5sec;
        	    fieldLabel[i] = "Pwr 5s";
            	fieldFormat[i] = "power";
			} else if (metric[i] == 39) {
    	        fieldValue[i] = AveragePower10sec;
        	    fieldLabel[i] = "Pwr 10s";
            	fieldFormat[i] = "power";
	        } else if (metric[i] == 80) {
    	        fieldValue[i] = (info.maxPower != null) ? info.maxPower : 0;
        	    fieldLabel[i] = "Max Pwr";
            	fieldFormat[i] = "power";  
			} else if (metric[i] == 71) {
            	fieldValue[i] = (uFTP != 0) ? runPower*100/uFTP : 0;
            	fieldLabel[i] = "%FTP";
            	fieldFormat[i] = "power";   
	        } else if (metric[i] == 72) {
    	        fieldValue[i] = (uFTP != 0) ? AveragePower3sec*100/uFTP : 0;
        	    fieldLabel[i] = "%FTP 3s";
            	fieldFormat[i] = "power";     	
			} else if (metric[i] == 73) {
    	        fieldValue[i] = (uFTP != 0) ? LapPower*100/uFTP : 0;
        	    fieldLabel[i] = "L %FTP";
            	fieldFormat[i] = "power";
			} else if (metric[i] == 74) {
        	    fieldValue[i] = (uFTP != 0) ? LastLapPower*100/uFTP : 0;
            	fieldLabel[i] = "LL %FTP";
            	fieldFormat[i] = "power";
	        } else if (metric[i] == 75) {
    	        fieldValue[i] = (uFTP != 0) ? AveragePower*100/uFTP : 0;
        	    fieldLabel[i] = "A %FTP";
            	fieldFormat[i] = "power";  
	        } else if (metric[i] == 76) {
    	        fieldValue[i] = (uFTP != 0) ? AveragePower5sec*100/uFTP : 0;
        	    fieldLabel[i] = "%FTP 5s";
            	fieldFormat[i] = "power";
			} else if (metric[i] == 77) {
    	        fieldValue[i] = (uFTP != 0) ? AveragePower10sec*100/uFTP : 0;
        	    fieldLabel[i] = "%FTP 10s";
            	fieldFormat[i] = "power";
            } else if (metric[i] == 107) {
	            if (workoutTarget != null) {
        			fieldValue[i] = (uOnlyPwrCorrFactor == false) ? (mPowerWarningunder + mPowerWarningupper)/2 : (mPowerWarningunder + mPowerWarningupper)/2/PwrCorrFactor;
        		} else {
	            	fieldValue[i] = (uOnlyPwrCorrFactor == false) ? uPowerTarget : uPowerTarget/PwrCorrFactor;
	            }
    	        fieldLabel[i] = "Ptarget";
        	    fieldFormat[i] = "power";
        	} else if (metric[i] == 117) {
	            fieldValue[i] = (workoutTarget != null) ? WorkoutStepLowBoundary : 0;
    		    fieldLabel[i] = "Ltarget";
        		fieldFormat[i] = "power";
        	} else if (metric[i] == 118) {
	            fieldValue[i] = (workoutTarget != null) ? WorkoutStepHighBoundary : 0;
        		fieldLabel[i] = "Htarget";
        	    fieldFormat[i] = "power";
        	} else if (metric[i] == 119) {
	            if (workoutTarget != null) {
	            	fieldValue[i] = (uFTP != 0) ? WorkoutStepLowBoundary*100/uFTP : 0;
    	        } else {
        			fieldValue[i] = 0;
        		}
        		fieldLabel[i] = "L%target";
        	    fieldFormat[i] = "power";
        	} else if (metric[i] == 120) {
	            if (workoutTarget != null) {
		            fieldValue[i] = (uFTP != 0) ? WorkoutStepHighBoundary*100/uFTP : 100;
    	        } else {
        			fieldValue[i] = 100;
        		}
        		fieldLabel[i] = "H%target";
        	    fieldFormat[i] = "power";
        	} else if (metric[i] == 121) {
	            fieldValue[i] = (workoutTarget != null) ? WorkoutStepNr : 0;
        		fieldLabel[i] = "Step nr";
        	    fieldFormat[i] = "0decimal";
        	} else if (metric[i] == 122) {
	            if (workoutTarget != null) {
		            if (WorkoutStepDurationType == 0) {
						fieldValue[i] = RemainingWorkoutTime;
						fieldLabel[i] = "Remain T";
        	    		fieldFormat[i] = "time";
					} else if (WorkoutStepDurationType == 1) {
						fieldValue[i] = RemainingWorkoutDistance;
						fieldLabel[i] = "Remain D";
        	    		fieldFormat[i] = "2decimal";
        	    	} else if (WorkoutStepDurationType == 5) {
						fieldValue[i] = 0;
						fieldLabel[i] = "Button";
        	    		fieldFormat[i] = "0decimal";
					}     
    	        } else {
        			fieldValue[i] = 0;
        			fieldLabel[i] = "No workout";
        	    	fieldFormat[i] = "0decimal";
        		}
        	}
        	//!einde invullen field metrics
		}
		//! Conditions for showing the demoscreen       
        if (uShowDemo == false) {
        	if (licenseOK == false && jTimertime > 900)  {
        		uShowDemo = true;        		
        	}
        }

	   //! Check whether demoscreen is showed or the metrics 
	   if (uShowDemo == false ) {

	   }   
	}

    function Formatting(dc,counter,fieldvalue,fieldformat,fieldlabel,CorString) {     
        var originalFontcolor = mColourFont;
        var Temp; 
        var x = CorString.substring(0, 3);
        var y = CorString.substring(4, 7);
        var xms = CorString.substring(8, 11);
        var xh = CorString.substring(12, 15);
        var yh = CorString.substring(16, 19);
        var xl = CorString.substring(20, 23);
		var yl = CorString.substring(24, 27);                  
        x = x.toNumber();
        y = y.toNumber();
        xms = xms.toNumber();
        xh = xh.toNumber();        
        yh = yh.toNumber();
        xl = xl.toNumber();
        yl = yl.toNumber();

		fieldvalue = (metric[counter]==38) ? mZone[counter] : fieldvalue;
		fieldvalue = (metric[counter]==99) ? mZone[counter] : fieldvalue;
		fieldvalue = (metric[counter]==100) ? mZone[counter] : fieldvalue;
		fieldvalue = (metric[counter]==101) ? mZone[counter] : fieldvalue;
		fieldvalue = (metric[counter]==102) ? mZone[counter] : fieldvalue;
		fieldvalue = (metric[counter]==103) ? mZone[counter] : fieldvalue;
		fieldvalue = (metric[counter]==104) ? mZone[counter] : fieldvalue;  
		fieldvalue = (metric[counter]==46) ? mZone[counter] : fieldvalue;
		
        if ( fieldformat.equals("0decimal" ) == true ) {
        	fieldvalue = fieldvalue.format("%.0f");  
        } else if ( fieldformat.equals("1decimal" ) == true ) {
            Temp = Math.round(fieldvalue*10)/10;
			fieldvalue = Temp.format("%.1f");
        } else if ( fieldformat.equals("2decimal" ) == true ) {
            Temp = Math.round(fieldvalue*100)/100;
            var fString = "%.2f";
            if (counter == 3 or counter == 4) {
   	      		if (Temp > 9.99999) {
    	         	fString = "%.1f";
        	    }
        	} else {
        		if (Temp > 99.99999) {
    	         	fString = "%.1f";
        	    }  
        	}    
        	fieldvalue = Temp.format(fString);        	
        } else if ( fieldformat.equals("pace" ) == true ) {
        	Temp = (fieldvalue != 0 ) ? (unitP/fieldvalue).toLong() : 0;
        	fieldvalue = (Temp / 60).format("%0d") + ":" + Math.round(Temp % 60).format("%02d");
        } else if ( fieldformat.equals("power" ) == true ) {   
        	fieldvalue = Math.round(fieldvalue).toNumber();
        	PowerWarning = (setPowerWarning == 1) ? 1 : PowerWarning;    	
        	PowerWarning = (setPowerWarning == 2) ? 2 : PowerWarning;
        	if (PowerWarning == 1) { 
        		mColourFont = Graphics.COLOR_PURPLE;
        	} else if (PowerWarning == 2) { 
        		mColourFont = Graphics.COLOR_RED;
        	} else if (PowerWarning == 0) { 
        		mColourFont = originalFontcolor;
        	}
        } else if ( fieldformat.equals("timeshort" ) == true  ) {
        	Temp = (fieldvalue != 0 ) ? (fieldvalue).toLong() : 0;
        	fieldvalue = (Temp /60000 % 60).format("%02d") + ":" + (Temp /1000 % 60).format("%02d");
        }
        		
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
        if ( fieldformat.equals("time" ) == true ) {    
	    		var fTimerSecs = (fieldvalue % 60).format("%02d");
        		var fTimer = (fieldvalue / 60).format("%d") + ":" + fTimerSecs;  //! Format time as m:ss
	    		var xx = x;
	    		//! (Re-)format time as h:mm(ss) if more than an hour
	    		if (fieldvalue > 3599) {
            		var fTimerHours = (fieldvalue / 3600).format("%d");
            		xx = xms;
            		dc.drawText(xh, yh, Graphics.FONT_LARGE, fTimerHours, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
            		fTimer = (fieldvalue / 60 % 60).format("%02d") + ":" + fTimerSecs;  
        		}
       			dc.drawText(xx, y, Garminfontklein, fTimer, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        } else {
 			if ( counter == 3 or counter == 4) {
        		dc.drawText(x, y, Garminfont, fieldvalue, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        	} else {
        		dc.drawText(x, y, Garminfontklein, fieldvalue, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
			}
        }         
       	dc.drawText(xl, yl, Graphics.FONT_XTINY,  fieldlabel, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        mColourFont = originalFontcolor;
		dc.setColor(mColourFont, Graphics.COLOR_TRANSPARENT);
    }

	function hashfunction(string) {
    	var val = 0;
    	var bytes = string.toUtf8Array();
    	for (var i = 0; i < bytes.size(); ++i) {
        	val = (val * 997) + bytes[i];
    	}
    	return val + (val >> 5);
	}

	function Lapaction () {
        var info = Activity.getActivityInfo();
        mLastLapTimerTime       	= jTimertime - mLastLapTimeMarker;
        mLastLapElapsedDistance 	= (info.elapsedDistance != null) ? info.elapsedDistance - mLastLapDistMarker : 0;
        mLastLapDistMarker      	= (info.elapsedDistance != null) ? info.elapsedDistance : 0;
        mLastLapTimeMarker      	= jTimertime;

        mLastLapTimerTimeHR			= mHeartrateTime - mLastLapTimeHRMarker;
        mLastLapElapsedHeartrate 	= (info.currentHeartRate != null) ? mElapsedHeartrate - mLastLapHeartrateMarker : 0;
        mLastLapHeartrateMarker     = mElapsedHeartrate;
        mLastLapTimeHRMarker        = mHeartrateTime;
  
        mLastLapTimerTimePwr		= mPowerTime - mLastLapTimePwrMarker;
        mLastLapElapsedPower  		= (info.currentPower != null) ? mElapsedPower - mLastLapPowerMarker : 0;
        mLastLapPowerMarker         = mElapsedPower;
        mLastLapTimePwrMarker       = mPowerTime;        

        mLaps++;	
	}

}
