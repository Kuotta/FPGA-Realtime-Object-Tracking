# -*- coding: utf-8 -*-
"""
Created on Tue Apr  26 09:20:07 2022

@author: cckuo6
"""

#%%
# import various libraries necessery to run your Python code
import time   # time related library
import sys    # system related library
ok_loc = 'C:\\Program Files\\Opal Kelly\\FrontPanelUSB\\API\\Python\\3.6\\x64'
sys.path.append(ok_loc)   # add the path of the OK library
import ok     # OpalKelly library
from PIL import Image
import matplotlib.pyplot as plt
import numpy as np 
import visa
import cv2


#%% 
# Define FrontPanel device variable, open USB communication and
# load the bit file in the FPGA
dev = ok.okCFrontPanel()  # define a device for FrontPanel communication
SerialStatus=dev.OpenBySerial("")      # open USB communicaiton with the OK board
ConfigStatus=dev.ConfigureFPGA("Final.bit"); # Configure the FPGA with this bit file
#ConfigStatus=dev.ConfigureFPGA("BT_Pipe_v1.bit"); # Configure the FPGA with this bit file

# Check if FrontPanel is initialized correctly and if the bit file is loaded.
# Otherwise terminate the program

print("----------------------------------------------------")
if SerialStatus == 0:
    print ("FrontPanel host interface was successfully initialized.")
else:    
    print ("FrontPanel host interface not detected. The error code number is:" + str(int(SerialStatus)))
    print("Exiting the program.")
    sys.exit ()
    
if ConfigStatus == 0:
    print ("Your bit file is successfully loaded in the FPGA.")
else:
    print ("Your bit file did not load. The error code number is:" + str(int(ConfigStatus)))
    print ("Exiting the progam.")
    sys.exit ()
print("----------------------------------------------------")
print("----------------------------------------------------")

#%%
# This section of the code cycles through all USB connected devices to the computer.
# The code figures out the USB port number for each instrument.
# The port number for each instrument is stored in a variable named “instrument_id”
# If the instrument is turned off or if you are trying to connect to the 
# keyboard or mouse, you will get a message that you cannot connect on that port.
device_manager = visa.ResourceManager()
devices = device_manager.list_resources()
number_of_device = len(devices)

power_supply_id = -1;
waveform_generator_id = -1;
digital_multimeter_id = -1;
oscilloscope_id = -1;

# assumes only the DC power supply is connected
for i in range (0, number_of_device):

# check that it is actually the power supply
    try:
        device_temp = device_manager.open_resource(devices[i])
        print("Instrument connect on USB port number [" + str(i) + "] is " + device_temp.query("*IDN?"))
        if (device_temp.query("*IDN?") == 'HEWLETT-PACKARD,E3631A,0,3.0-6.0-2.0\r\n'):
            power_supply_id = i      
        if (device_temp.query("*IDN?") == 'Agilent Technologies,33511B,MY52301256,3.03-1.19-2.00-52-00\n'):
            waveform_generator_id = i
        if (device_temp.query("*IDN?") == 'Agilent Technologies,34461A,MY53207918,A.01.10-02.25-01.10-00.35-01-01\n'):
            digital_multimeter_id = i       
        if (device_temp.query("*IDN?") == 'KEYSIGHT TECHNOLOGIES,MSO-X 3024T,MY55100352,07.10.2017042905\n'):
            oscilloscope_id = i     
        device_temp.close()
    except:
        print("Instrument on USB port number [" + str(i) + "] cannot be connected. The instrument might be powered of or you are trying to connect to a mouse or keyboard.\n")
    

#%%
# Open the USB communication port with the power supply.
# The power supply is connected on USB port number power_supply_id.
# If the power supply ss not connected or turned off, the program will exit.
# Otherwise, the power_supply variable is the handler to the power supply

    
if (power_supply_id == -1):
    print("Power supply instrument is not powered on or connected to the PC.")    
else:
    print("Power supply is connected to the PC.")
    power_supply = device_manager.open_resource(devices[power_supply_id]) 
    
    
#%%
power_supply.write("*CLS")
print(power_supply.write("OUTPUT ON")) # power supply output is turned on

#%% 
# The register address list we would like to configure
reg_addr_list = [1,2,3,4,39,42,43,44,57,58,59,60,68,69,80,83,97,98,100,101,102,103,106,107,108,109,110,117]
# The register corresponding value list we would like to configure
reg_value_list = [232,1,0,0,1,232,3,0,3,44,240,10,2,9,2,187,240,10,100,98,34,64,94,110,91,82,80,91]

# check if SPI is IDLE
dev.UpdateWireOuts()
while(dev.GetWireOutValue(0x23) != 1):
    dev.UpdateWireOuts()
    continue
    
print("Start writting to register")
for i in range(len(reg_addr_list)):
    start_bit = 0
    dev.SetWireInValue(0x03, start_bit)
    dev.UpdateWireIns()
    time.sleep(0.1)
    start_bit = 1
    dev.SetWireInValue(0x00, reg_addr_list[i])
    dev.SetWireInValue(0x01, 1) 
    dev.SetWireInValue(0x02, reg_value_list[i])
    dev.UpdateWireIns()  
    time.sleep(0.1)
    dev.SetWireInValue(0x03, start_bit)
    dev.UpdateWireIns()  
    time.sleep(0.1)
    dev.UpdateWireOuts()
    while(dev.GetWireOutValue(0x21)!=1):
            continue
            
print('Register configuration done')
    
# Send frame request signal
dev.SetWireInValue(0x04, 1)
dev.UpdateWireIns()
time.sleep(0.01)

dev.SetWireInValue(0x04, 0)
dev.UpdateWireIns()

PipeOut_array = np.arange(315392).astype('uint8')
array_reshape = np.arange(648*486).astype('uint8')

PipeOut_array_1 = np.arange(315392).astype('uint8')
array_reshape_1 = np.arange(648*486).astype('uint8')

# check if SPI is done transmitting
while(dev.GetWireOutValue(0x23) != 1):
    dev.UpdateWireOuts()
    continue

print('Receiving data from block pipe: '+str(dev.ReadFromBlockPipeOut(0xa0, 1024, PipeOut_array)))

array_reshape = PipeOut_array[0:648*486]
array_reshape = array_reshape.reshape(486,648)

def Real_time_image_1():
    dev.SetWireInValue(0x05, 1) 
    dev.UpdateWireIns()
    dev.SetWireInValue(0x05, 0)
    dev.UpdateWireIns()

    dev.ReadFromBlockPipeOut(0xa0, 1024, PipeOut_array)
    array_reshape = PipeOut_array[0:648*486]

    return array_reshape.reshape(486,648)

def Real_time_image_2():
    dev.SetWireInValue(0x05, 1) 
    dev.UpdateWireIns()
    dev.SetWireInValue(0x05, 0)
    dev.UpdateWireIns()

    dev.ReadFromBlockPipeOut(0xa0, 1024, PipeOut_array_1)
    array_reshape_1 = PipeOut_array_1[0:648*486]

    return array_reshape_1.reshape(486,648)
    
framecount = 0
pix_list = []

power_supply.write("APPLy P6V, %0.2f, 0.5" % 5.0)
dev.SetWireInValue(0x07,0) #Enable PIN
dev.UpdateWireIns()
time.sleep(0.01)

while True:
    img_1 = Real_time_image_1()
    img_2 = Real_time_image_2()
    img_diff = np.absolute(np.subtract(img_2, img_1))
    coordinates = []
    coordinates = np.where((img_diff > 10)&(img_diff < 250))[1]

    if(len(coordinates)>0):
        coor_avg = sum(coordinates)//len(coordinates)
    
    if(coor_avg>390):
        dev.SetWireInValue(0x06,0) #Direction PIN 
        dev.SetWireInValue(0x07,1) #Enable PIN
        dev.SetWireInValue(0x08,25) #Number of pulse
        dev.UpdateWireIns()
        print("Rotate Clockwise")
    elif(coor_avg<220):
        dev.SetWireInValue(0x06,1) #Direction PIN
        dev.SetWireInValue(0x07,1) #Enable PIN
        dev.SetWireInValue(0x08,25) #Number of pulse
        dev.UpdateWireIns()
        print("Rotate CounterClockwise")
    else:
        dev.SetWireInValue(0x07,0) 
        dev.UpdateWireIns()
    
    # Read data from acceleration sensor
    dev.UpdateWireOuts()
    XHA = dev.GetWireOutValue(0x24)
    YHA = dev.GetWireOutValue(0x25)
    ZHA = dev.GetWireOutValue(0x26)

    if XHA > 32768:
        XHA = XHA - 65536

    if YHA > 32768:
        YHA = YHA - 65536

    if ZHA > 32768:
        ZHA = ZHA - 65536    

    print("--------Acceleration Data---------")
    print("x:%.2f"%(XHA/16*0.001))
    print("y:%.2f"%(YHA/16*0.001))
    print("z:%.2f"%(ZHA/16*0.001))
    
    dev.SetWireInValue(0x07,0) 
    dev.UpdateWireIns()
    
    framecount += 1
    cv2.imshow('test',img_1)
    cv2.waitKey(1)
    if(framecount==500):
        break

print(power_supply.write("OUTPUT OFF"))
power_supply.close()
#end_time =  time.time()
#print("Time required for displaying 100 frame: " + str(end_time-start_time))
#fps = 100/(end_time - start_time)
#print("fps: " + str(fps))
#print(pix_list)
cv2.destroyAllWindows()
dev.Close
