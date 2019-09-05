<?xml version="1.0" encoding="utf-8"?>
<?AutomationStudio Version=4.5.3.86 SP?>
<SwConfiguration CpuAddress="SL1" xmlns="http://br-automation.co.at/AS/SwConfiguration">
  <TaskClass Name="Cyclic#1" />
  <TaskClass Name="Cyclic#2" />
  <TaskClass Name="Cyclic#3" />
  <TaskClass Name="Cyclic#4" />
  <TaskClass Name="Cyclic#5" />
  <TaskClass Name="Cyclic#6" />
  <TaskClass Name="Cyclic#7" />
  <TaskClass Name="Cyclic#8">
    <Task Name="FileExplor" Source="mappFileExplorer.FileExplorer.prg" Memory="UserROM" Language="ANSIC" Debugging="true" />
    <Task Name="USBdevice" Source="mappFileExplorer.USBdevice.prg" Memory="UserROM" Language="IEC" Debugging="true" />
  </TaskClass>
</SwConfiguration>