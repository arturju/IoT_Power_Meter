<?php	// variables for headers
$page_title= "ESP8266";
$page_description= "ESP8266 page";
?>

<!--=============== HEADERS ======== -->
<head>
		<title> <?php echo $page_title; ?> </title>
		<meta http-equiv="description" content="<?php echo $page_description; ?>" />
		<meta http-equiv="pragma" content="no-cache" />
		
		<link href="//maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css" rel="stylesheet" >
		<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap-theme.min.css">
		
		
		<script src="http://ajax.googleapis.com/ajax/libs/jquery/2.0.2/jquery.min.js"></script>
		<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min.js"></script>
		<script src="http://ajax.aspnetcdn.com/ajax/knockout/knockout-2.2.1.js"></script>
		<script src="js/sevenSeg.js"></script>
		
		
		<!-- To resize based on screen size -->
		<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
		
</head>

<style>
.bordered {
	margin-top:10px;
	border: #cdcdcd medium solid;
	border-radius: 10px;
	-moz-border-radius: 10px;
	-webkit-border-radius: 10px;
}

.pass {
	background:#DFF2BF;
}

.fail {
	background:#FFBABA;
}

.neutral{
	background:#BDE5F8;
}

</style>

<script>
    function getStatus(){
        $.ajax({
            url: "http://192.168.14.77",	// NodeMCU's IP
            type: "get",
            data: {"req":"ajax"},
			error: function (xhr, status, error) {
				console.log('Error: ' + error.message);
				/* $('#lblResponse').html('Error connecting to the server.'); */
			},
            success: function(r){
			// client receives: 119.6V, 0.13A, 0.016kW			
				var voltage = r.substring(0, r.indexOf('V'));
				var current = r.substring( r.indexOf('A') - 5, r.indexOf('A'));
				var wattage = r.substring( r.indexOf('W') - 4, r.indexOf('W'));						
				
                $("#voltage").sevenSegArray({ digits: 4, value: voltage } )
				$("#current").sevenSegArray({ digits: 4, value: current } )
				$("#wattage").sevenSegArray({ digits: 4, value: wattage } )
				
				var wattageMin = 244;	// @ 120Vac
				var wattageMax = 252;
				
				var resistanceMin = (120*120)/wattageMax;		// R = (V^2)/P
				var resistanceMax = (120*120)/wattageMin;
				
				var wattageMinSmart = (voltage*voltage)/resistanceMax;	// P = (V^2)/R
				var wattageMaxSmart = (voltage*voltage)/resistanceMin;
				
				//console.log(wattageMinSmart + " | " + wattageMaxSmart);
				document.getElementById("wattMinSmart").innerHTML = wattageMinSmart.toFixed(1) ;
				document.getElementById("wattMaxSmart").innerHTML = wattageMaxSmart.toFixed(1) ;
				
			//---- end of parsing response
			
                $("#voltage").sevenSegArray({ digits: 4, value: voltage } )
				$("#current").sevenSegArray({ digits: 4, value: current } )
				$("#wattage").sevenSegArray({ digits: 4, value: wattage } )
				
				$("#voltageS").sevenSegArray({ digits: 4, value: voltage } )
				$("#currentS").sevenSegArray({ digits: 4, value: current } )
				$("#wattageS").sevenSegArray({ digits: 4, value: wattage } )
					
			// ----- DUMB power meter pass/fail ---						
				if ( (wattage < wattageMin) || (wattage > wattageMax) ) {
					document.getElementById("staticRange").className = "row fail text-center";
				}
				else if ( (wattage > wattageMin) && (wattage < wattageMax) ) {
					document.getElementById("staticRange").className = "row pass text-center";
				}	

				//---------- SMART power meter pass/fail
				if ( (wattage < wattageMinSmart) || (wattage > wattageMaxSmart) ) {
					document.getElementById("dynamicRange").className = "row fail text-center";
				}
				else if ( (wattage > wattageMinSmart) && (wattage < wattageMaxSmart) ) {
					document.getElementById("dynamicRange").className = "row pass text-center";
				}				
				
			/* 	if (wattage == "A, 0"){					
					document.getElementById("staticRange").className = "row text-center";
					document.getElementById("dynamicRange").className = "row text-center";
				} */
				console.log(wattage);
				
            }	// end of function
        });
        setTimeout('getStatus()', 1000);      // every 1.0 seconds
    }	
</script>



<body onLoad="getStatus()">		
    
	<!--
<h1 class="text-center"> IoT Power Meter  </h1>
-->

<br><br>


<div class="container">
<!-- main content -->
<div class="row">

<div class="col-sm-12 bordered">	

	<!-- DUMB Power Meter -->
	
	<div class="col-sm-8 bordered ">		
	
	<h2 class="text-center"><u> Smart Power Meter </u></h2>
		<!-- Voltage -->
		<div id="voltageDisplay" class="row">		
			<div class="col-xs-5">
				<div id="voltage" style="max-width: 200px; height: 75px;"> </div>
			</div>
			<div class="col-xs-4">
				<br><h2>Volts</h2>
			</div>
			<div class="col-xs-3"> </div>
			
		</div>
		
		<!-- Current -->
		<div id="currentDisplay" class="row">		
			<div class="col-xs-5">
				<div id="current" style="max-width: 200px; height: 75px;"> </div>
			</div>
			<div class="col-xs-4">
				<br><h2>Amps</h2>
			</div>
			<div class="col-xs-3"> </div>
		</div>
		
		<!-- Wattage -->
		<div id="wattageDisplay" class="row">		
			<div class="col-xs-5">
				<div id="wattage" style="max-width: 200px; height: 75px;"> </div>
			</div>
			<div class="col-xs-4">
				<br><h2>Watts</h2>
			</div>
			<div class="col-xs-3"> </div>
			
		</div>
		<h2 id="staticRange" class="text-center">
			<em style="color:orange;" >Static Range:  244  - 252 W <br></em>
		</h2>
		<h2 id="dynamicRange" class="text-center">
			<b style="color:blue;">Dynamic Range: </b><b style="color:blue;" id="wattMinSmart"> .. </b><b>-</b> <b style="color:blue;" id="wattMaxSmart">... <br></b>
		</h2>
		
		
	</div>
	
	<!----------- PARAMETERS ---->
	<div class="col-sm-4 bordered text-left" style="background: #FEEFB3;">	
	
	<br>
	 <h3>Parameters Given:
		<br>
		<p> <small> @ 120V<sub>AC</sub> and 60HZ </small> </p>
		
			<br>
			Wattage: <br>
			<em>244-252 W</em>
			<br><br>
	</h3>			
	</div>


	
<!-- end -->

</div>	<!-- end of main content -->

</div> <!-- end of first row -->

</div>

<br>

</div> <!-- end of container  -->





</body>





