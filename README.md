

# sbm-cordova-plugin-epos2  
  
Cordova plugin for Epson ePOS SDK for  Android.  
  
##  API  
### Printer Discovery  
  
##### .discoverPrinters('start',successCallback, errorCallback)  
   
    SbmCordovaPluginEpos2.discoverPrinters('start', () => { 
    // success callback 
    } ,(error) => {
    // error callback
    }) 

##### .getPrintersList('show', successCallback, errorCallback)  
  
  ```  
SbmCordovaPluginEpos2.getPrintersList('show', () => { 
// success callback 
},(error) => {
// error callback    
})  
  ```  
  
##### .stopDiscoverPrinters('stop',successCallback, errorCallback)  
  ```  
SbmCordovaPluginEpos2.stopDiscoverPrinters('stop',() => {
// success callback
} ,(error) => {
// error callback
})   
 ```  
### Printing   
#### SbmCordovaPluginEpos2.printText(jsonObject, successCallback, errorCallback)  
```  
SbmCordovaPluginEpos2.printText(jsonObject,() => {  
// success callback
},(error) => {  
// error callback
})  
```  
  
##### JsonObject Format  example   

      {    
    printer: {    
         printerTarget:"BT:00:01:90:C6:12:49",    
         printerSeries:2,    
         lang: 0    
    },    
    data:     
           [   
           {    
               data: " Scheidt & Bachmann  \n",   
               type: "text",    
               addFeedLine:1      
           },    
           {    
            data: "6008560110019 1518",    
	        type: "qrCode",    
           }    
           ] }  


# Properties

## printerTarget 
	Specifies the identifier used for identification of the target device(MAC ADDRESS)
## printerSeries 
	
	| Model Name  |  code      |  
	|-------------|------------| 
	|  TM_M10     |     0      |
	|  TM_M30     |     1      |
	|  TM_P20     |     2      |
	|  TM_P60     |     3      |
	|  TM_P60II   |     4      |
	|  TM_P80     |     5      |
	|  TM_T20     |     6      |
	|  TM_T60     |     7      |
	|  TM_T70     |     8      |
	|  TM_T81     |     9      |
	|  TM_T82     |     10     |
	|  TM_T83     |     11     |
	|  TM_T88     |     12     |
	|  TM_T90     |     13     |
	|  TM_T90KP   |     14     |
	|  TM_U220    |     15     |
	|  TM_U330    |     16     |
	|  TM_L90     |     17     |
	|  TM_H6000   |     18     |
	|  TM_T83III  |     19     |
	|  TM_T100    |     20     |

## lang 

	
	| language        |  code      |  
	|-----------------|------------| 
	|  MODEL_ANK      |     0      |
	|  MODEL_JAPANESE |     1      |
	|  MODEL_CHINESE  |     2      |
	|  MODEL_TAIWAN   |     3      |
	|  MODEL_KOREAN   |     4      |
	|  MODEL_THAI     |     5      |
	|  MODEL_SOUTHASIA|     6      |

## type 
text =>print text 
quCode => print QrCode
 default => text
##  addFeedLine
Specifies the paper feed space (in lines). Specifies an integer from 0 to 255.

##  alignText 

Adds the text alignment setting to the command buffer.  (default1)

 	|   Align         |  code      |  
	|-----------------|------------| 
	|   Center        |     1      |
	|   Right         |     2      |
	|   Left          |     0      |
 
## textSizeWidth
	
	Specifies the horizontal scale of text
## textSizeHeight
	Specifies the vertical scale of text

## qrCodeWidth
	Specifies the horizontal scale of QrCode


## qrCodeHeight
	Specifies the vertical scale of QrCode

## styles
	example:
	styles: {
		reverse: -2,
		ul: -2,
		em: 1,
		color: -2
	}
 Adds the text style setting to the command buffer.
#### reverse
Specifies inversion of black and white for text. 

	| Value           |  Description 						      |  
	|-----------------|-------------------------------------------------------------------| 
	|  MODEL_ANK      |   Specifies the inversion of black and white parts of characters  |
	|  MODEL_JAPANESE |    Cancels the inversion of black and white parts of characters   |



#### ul
Specifies the underline style

	| Value           |  Description 	     | 
	|-----------------|--------------------------| 
	|  1              |  Specifies underlining.  |
	|  0              |  Cancels underlining.    |
	
#### em
Specifies the bold style

	| Value           |  Description 				  |  
	|-----------------|-----------------------------------------------| 
	|  1 	          | Specifies emphasized printing of characters.  |
	|  0              |  Cancels emphasized printing of characters.   |
	 
#### color
Specifies the color.

		| Value         |  Description                |  
		|---------------|-----------------------------| 
		|  0		| Characters are not printed  |
		|  1		| First  color  	      |
		|  2		| Second color 	              |
		|  3		| Third color                 |
		|  4		| Fourth color                |
