require 'rubygems'
require 'openssl'
require 'mqtt'

# input the setting
host = 'xxxxx'
port = 16002
port_tls = 26002
cafile = '/etc/mosquitto/ca/ca.crt'
username = 'adminuser'
password = 'password'
limit = 55

# begin to test

client = MQTT::Client.new

puts '-------- SSL on PC ------------'
puts OpenSSL::SSL::SSLContext::METHODS
puts '-------------------------------'

# def connection
def connect(host, username, password, port)
  client_var = MQTT::Client.connect(
  :host => host,
  :username => username,
  :password => password,
  :port => port
  )
  return client_var
end

def connect_tls(host, username, password, port_tls, cafile)
  client_var = MQTT::Client.new
  client_var.host = host
  client_var.ssl = true
  client_var.username = username
  client_var.password = password
  client_var.port = port_tls
  client_var.ca_file = cafile
  client_var.connect()
  return client_var
end

# Test the basic Port
begin
client = connect(host, username, password, port)
#client.connect()
puts "Conect to MQTT Port: SUCCESS"
rescue MQTT::ProtocolException 
	puts "Conected MQTT Port:  FAIL"
end
client.disconnect()
# Test the TLS Port
begin
	client = connect_tls(host, username, password, port_tls, cafile)
#client.connect()
	puts "Connect to  MQTT_TLS Port: SUCCESS"
rescue OpenSSL::SSL::SSLError
	puts "Connected MQTT_TLS POrt:  FAIL SSL_Error "
rescue MQTT::ProtocolException
        puts "Connected MQTT_TLS Port:  FAIL"
end
client.disconnect()

# Test the Pub/Sub with QOS 0-2
client = connect(host, username, password, port)
begin

client.subscribe(['test',0])
client.publish('test',"1",qos = 0)
topic, message = client.get
if (topic == "test" && message == "1" )
 	 puts "Sub/Pub QOS0 : SUCCESS"
else
	 puts "Sub/Pub QOS0 : FAIL"
end
client.subscribe(['test',1])
client.publish('test',"1",qos = 1)
topic, message = client.get
if (topic == "test" && message == "1" )
	puts "Sub/Pub QOS1 : SUCCESS"
else
        puts "Sub/Pub QOS1 : FAIL"
end
client.subscribe(['test',2])
client.publish('test',"1",qos = 2)
topic, message = client.get
if (topic == "test" && message == "1" )
        puts "Sub/Pub QOS2 : SUCCESS"
else
        puts "Sub/Pub QOS2 : FAIL"
end

rescue
puts "Sub/Pub      : FAIL"
end

# Test the Retain

client.publish('test',"1", retain=true , qos=2)
client.disconnect()
client.connect()
client.subscribe('test')
topic, message = client.get
if (topic == "test" && message == "1" )
        puts "Retain Message : SUCCESS"
else
        puts "Retain Message : FAIL"
end

# Test the dup

client.subscribe('A/+/C','A/#')
client.publish('A/B/C',"2")
client.publish('A/B/C',"3")
client.publish('A/B/C',"4")
count = 0
client.get do |topics,messages|
	if messages == "2" then
		count = count + 1	
	elsif messages == "4" then
		break
	end
end

if( count > 1 )
	puts "Dup : allow the Dup_msg"
else
	puts "Dup : Not allow the Dup_msg"
end

# Test the limit

testString = "123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234"
content = ""
for a in 0..limit do
	content = content + testString
end

client.subscribe('test')
Thread.new do
    20.times do
      sleep(1)  
      client.publish('test', content)
    end
end

start_time = Time.now
puts "--- Start Test the Limit(20s)---"
count = 0;

Thread.new do
    client.get('test') do |topics, msg|
	count = count+1
    end
end

sleep(20)
#puts Time.now
if(count != 20) 
	puts "the Limit : is work, '#{count}'"
else
	puts "the Limit : Not work, '#{count}'"	
end


