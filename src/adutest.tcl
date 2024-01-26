
load ./adutcl.so
try {
    set handle [adu::open_device 2567 100]    
} trap {} {message optdict} {
    puts $message
    puts "I caught it"
    exit
}

adu::write_to_adu $handle "RK0" 200
adu::write_to_adu $handle "SK0" 200

adu::write_to_adu $handle "RUN00" 200
set myval [adu::read_from_adu $handle 8 200]
puts "Full return is $myval"
puts "Second list element is [lindex $myval 1]"

puts [adu::device_list]
# set myval [adu::serial_number $handle]
