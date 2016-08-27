----------------
-- Wifi Setup --
----------------
wifi.setmode(wifi.STATION)
wifi.sta.config("9F35FE","55463423")
--print(wifi.sta.getip())

--------------------
-- GPIO Setup--
--------------------
led1 = 3
led2 = 4
potPin = 0

led1State = 0
led2State = 0

gpio.mode(led1, gpio.OUTPUT)
gpio.mode(led2, gpio.OUTPUT)
gpio.mode(potPin, gpio.INPUT, gpio.PULLUP)

----------------
-- Web Server --
----------------
print("Starting Web Server...")
srv=net.createServer(net.TCP,30)    -- 30 second timeOut

srv:listen(80,function(conn)        -- listen for server on port 80
    conn:on("receive", function(client, requestReceived)
        --print(requestReceived)              
        
        -- HTTP Response to allow Cross-Origin RequeSts (CORS)
        client:send(
          "HTTP/1.1 200 OK\r\n"
        .."Content-Type: text/html\r\n Connection: keep-alive\r\n"
        .."Access-Control-Allow-Origin: *\r\n"
        .."\r\n");

        -------------------------------------------------------------------------------
        -- Tutorial: http://lua-users.org/wiki/PatternsTutorial
        -- Typical request: "GET /?pin=ON1 HTTP/1.1 ".      Must match Exactly. (GET /favicon.ico doesn't match)
        -- method= 'GET'  +   path = '/'   +   ('?') + vars='pin=ON1' + ('HTTP')        
        -------------------------------------------------------------------------------
        local firstChar, lastChar, method, path, vars = string.find(requestReceived, "([A-Z]+) (.+)?(.+) HTTP");        
        
        local _GET = {}
        if (vars ~= nil)then         
            -- separates 'pin=ON1' into 'k=pin' and v='ON1'.
            for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do         -- http://www.lua.org/pil/20.2.html
                _GET[k] = v
            end
        end

        -- Simple Web Page --
        simplePage = "<h1> Click <a href=\"http://192.168.1.5/projects/ESP8266.php\">here</a> for full page </h1>"; 
        
        if    (_GET.pin == "ON1")then 

            if     (led1State == 0)  then   led1State = 1;
            elseif (led1State == 1)  then   led1State = 0;
            end
            gpio.write(led1, led1State);

        elseif(_GET.pin == "OFF1")then              gpio.write(led1, gpio.LOW);
        elseif(_GET.pin == "ON2")then               gpio.write(led2, gpio.HIGH);
        elseif(_GET.pin == "OFF2")then              gpio.write(led2, gpio.LOW);
        elseif(_GET.req == "ajax")then              
              client:send(adc.read(potPin)); 
              client:close();
              collectgarbage();                           
        end

        client:send(simplePage);
        client:close();
        collectgarbage();
    end)    -- end of 'Receive'    
end)    -- end of serv:listen(80, function(conn) )

