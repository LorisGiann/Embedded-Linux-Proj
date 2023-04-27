# Automated Plant Watering System

Our Project designed for the Embedded Linux Course at SDU in the Spring Semester 2023

## Modules
The modules were designed according to the following diagram. Each module performs an isolated task

![Module Diagram](img/ModuleDiagram.jpeg)
### PICO Read Module
- [x] In Progress
- [ ] Done

Reads serial input from PICO and outputs data to appropriate topics
### Water Request Gate
- [x] In Progress
- [ ] Done

Reads the .../pump_request topic and .../water_alarm topic. If there is no alarm and a request, it signals the pump to activate
### Regular Water Module
- [ ] In Progress
- [ ] Done

Every 12 hours, request to pump
### Moisture Water Module
- [ ] In Progress
- [ ] Done

Read .../soil_moisture topic. If low, request to pup
### Button Water Module
- [ ] In Progress
- [ ] Done

If the .../button_count is one, request to pump
### LED Module
- [ ] In Progress
- [ ] Done

if Water alarm or plant alarm, light RED
else if Moisture Low, YELLOW
else GREEN
### Log Module
- [ ] In Progress
- [ ] Done

Log data to mqtt for graphana


## Graphana Interface
- [ ] Done

Show logged info on Graphana Dashboard