# This is a sample Python script.
from datetime import datetime

import sys
import time
import serial
# Press Shift+F10 to execute it or replace it with your code.
# Press Double Shift to search everywhere for classes, files, tool windows, actions, and settings.


def captureData(ComPort, SavePath):

    # Initialize Serial Ports
    s = serial.Serial(ComPort, 9600)

    minutes = 1;
    t_end = time.time() + 60 * minutes
    while time.time() < t_end:
        # Read serial data stream
        res = s.read(10000)

    # Initialize Log File
    curtimeDT = datetime.now();
    curtimeSTR = curtimeDT.strftime("%d_%M_%Y_%H_%M_%S")
    filename = SavePath + "Log" + curtimeSTR + ".txt"
    fid = open(filename, 'w')
    sys.stdout = fid

    # Print serial data stream to log file
    print(res)



# Press the green button in the gutter to run the script.
if __name__ == '__main__':
    ComPort = 'Com4'
    SavePath = 'D:\Hobby_Shit\Data\GPS\\'
    captureData(ComPort, SavePath);

# See PyCharm help at https://www.jetbrains.com/help/pycharm/
