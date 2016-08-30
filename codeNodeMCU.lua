-- Power Meter PZEM-004(v3.0)
-- by Arturo Jumpa

-- Wifi Setup --
wifi.setmode(wifi.STATION)
wifi.sta.config("SSID-name","password")
--uart.setup(0, 9600, 8, 0, 1, 1)     -- uart.setup( id, baud, databits, parity, stopbits, echo )

string = ""
responseToClient = ""
counter = 0

uartCounter = 0
receivedAll = 0
uartWriteCycle = 0
startTimer = 0
timerStarted = 0

-- This function gets called when the alarm is triggered (every .35 seconds)
-- and sends packets to poewr meter so it can respond with appropiate value. It gets interrupted 
-- by the UART callBack Function when the meter responds.
-- Function must be defined here as prototype. Lua code executes sequentially (?) 
function writeToUART()
    
    if ( (uartWriteCycle >= 1) and (receivedAll < 1) ) then
        tmr.stop(0)
        timerStarted = 0;
        uartWriteCycle = 0;        
    end
    
    if ( receivedAll >= 1) then
       -- print("Ready to send" )
        tmr.stop(0)
        startTimer = 0
        timerStarted = 0
        uartWriteCycle = 0        
    end
      
    ---- weird hardware bug with power meter.. 1st request responds in <10ms, 2nd and 3rd requests can take up to 600ms
    if ( (uartCounter == 0) and (timerStarted == 1) ) then
        --print("voltage Req")
        uart.write(0, 0xB0,0xC0,0xA8,0x01,0x01,0x00,0x1A)       -- voltage
        uartCounter = uartCounter + 1
        counter = 0
        
    elseif(uartCounter == 1) then
       -- print("current Req")
        uart.write(0, 0xB1,0xC0,0xA8,0x01,0x01,0x00,0x1B)       -- current
        uartCounter = uartCounter + 1
		
    elseif(uartCounter == 2) then                               -- gap to wait for current receipt. 
        uartCounter = uartCounter + 1
		
    elseif(uartCounter == 3) then
        uart.write(0, 0xB2,0xC0,0xA8,0x01,0x01,0x00,0x1C)       -- Wattage
        uartCounter = uartCounter + 1
        
    elseif(uartCounter == 4) then                               -- gap to wait for wattage receipt
        uartCounter = 0
        uartWriteCycle = uartWriteCycle + 1
    end
        
end

voltageValue = 0
currentValue = 0
wattageValue = 0

-- Page on the NodeMCU. Points to separately hosted page --
simplePage = "<h1> Click <a href=\"http://192.168.11.55/ESP8266.php\">here</a> for full page </h1>"; 

-- Start Web Server --
print("Starting Web Server...")
srv=net.createServer(net.TCP, 30)   	-- 30 second timeOut
   
    srv:listen(80,function(conn)        -- listen for server on port 80. 

        --- callback function when data is received --
        conn:on("receive", function(client, requestReceived)
            --print(requestReceived)                          
            client:send(                 
              "HTTP/1.1 200 OK\r\n"
            .."Content-Type: text/html\r\n Connection: keep-alive\r\n"
            .."Access-Control-Allow-Origin: *\r\n"      -- HTTP Response to allow Cross-Origin Requests (CORS)
            .."\r\n");
    
            -------------------------------------------------------------------------------
			-- Parse HTTP string and decide what to do based on request.
            -- Tutorial: http://lua-users.org/wiki/PatternsTutorial
            -- Typical request: "GET /?pin=ON1 HTTP/1.1 "
            -- method= 'GET'  +   path = '/'   +   ('?') + vars='pin=ON1' + ('HTTP')        
            -------------------------------------------------------------------------------
            local firstChar, lastChar, method, path, vars = string.find(requestReceived, "([A-Z]+) (.+)?(.+) HTTP");        
            if(method == nil)then
                firstChar, lastChar, method, path = string.find(requestReceived, "([A-Z]+) (.+) HTTP");
            end
            local _GET = {}
            if (vars ~= nil)then            -- vars Not = nil. separates 'pin=ON1' into 'k=pin' and v='ON1'.            
                for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do         -- http://www.lua.org/pil/20.2.html
                    _GET[k] = v
                end
            end
            ----------------------------------------------------------------------------------
           
            if(_GET.req == "ajax")then       --ajax Call. Sends to client the values it has in memory for V, A and W       
                startTimer = 1   
                responseToClient = ( voltageValue.."V, "..currentValue.."A, "..wattageValue.."W" )
                client:send(responseToClient);
                print("Sent: "..responseToClient)                                                                        
                
                if (receivedAll >= 1) then
                   -- print("clearing strings")                
                    responseToClient = ""    
                    string = ""
                    receivedAll = 0
                    uartWriteCycle = 0
                end 
            else    
                client:send(simplePage);         -- no 'ajax' on HTTP request       
            end
            
            -- if timer was set to Start and it has not yet started then start it. Otherwise it's already started
            if ( (startTimer == 1) and (timerStarted == 0) ) then
                --uart.write(0, 0xB4,0xC0,0xA8,0x01,0x01,0x00,0x1E)     -- set address? Not needed apparently
                tmr.alarm(0, 350, 1, writeToUART) 						-- runs function every .35 seconds
                timerStarted = 1;
            end

            client:close();
            collectgarbage();

        end)    -- end of 'Receive'    
    end)    -- end of serv:listen(80, function(conn) )

    
------ UART callBack Functions    
    uart.on("data", 1,
        function(receipt)               				-- received 1 char (8-bits, 1 byte from UART)
            --print(" -")
            if ( (string.byte(receipt) ) == 160) then   -- response with voltage value; A0 hex (160 decimal)
                counter = 0								-- start counting bits. Assumes no loss
                string = ""
            end
            counter = counter + 1 
            
            if (counter > 0)    then
                string = string..string.byte(receipt)..":"                      
            end    
            
            --- VOLTAGE---------------------------------
            if (counter == 3) then
                voltageValue = string.byte(receipt)
            end
            if (counter == 4) then
                voltageValue = voltageValue.."."..string.byte(receipt)
            end
            ------------------------------------------
            
            --- CURRENT--------------------------------
            if (counter == 10) then
                currentValue = string.byte(receipt)
            end
            if (counter == 11) then
                local decimalTemp = string.byte(receipt)
                    
                if (decimalTemp < 10) then
                    currentValue = currentValue..".0"..decimalTemp
                else 
                    currentValue = currentValue.."."..decimalTemp                                        
                end

            end
            --------------------------------------------
            
            ---  WATTAGE--------------------------------
            if (counter == 16) then
                wattageValue = string.byte(receipt)*256
            end
            if (counter == 17) then
                wattageValue = (tonumber(wattageValue) + string.byte(receipt))
            end
            --------------------------------------------              
                
            if (counter == 21)   then           -- received 3 readings of 7 bytes. voltage, current, wattage
                print("pMeter: "..string)
                counter = 0
                receivedAll = receivedAll + 1
                uartWriteCycle = 0
            end    
             
            if receipt=="quit" then 
                uart.on("data") 
            end
        
    end, 0)  



