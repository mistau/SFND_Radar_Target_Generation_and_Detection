# Radar Target Generation and Detection #
Project from the Sensor Fusion Nanodegree of Udacity

## Project Overview

![](./report/processing_flow.png)

The processing flow in the Matlab project consists of the following steps:
- Moving Target Generation
- FMCW configuration: here the parameters for slope and alike are calculated from the requirements
- FMCW Waveform Generation
- Range Measurement
- Range Doppler Response
- CFAR Detection

## System Requirements

The radar systems requirements given for this project are outlined in the table below.

![](./report/requirements.png)

## Target Generation

For the target I decided to pick the following values.
![](./report/target_definition.png)

## FMCW Configuration

Out of the system requirements parameters like bandwidth, chirp time and slope are generated
using the formulars introduced in the course.

![](./report/waveform_generation.png)

The calculated slope is 2.0455e+13 which matches the value giving in the rubic.

## Waveform Generation

The waveforms of the transmitted signal Tx, the received signal Rx and the mixer signal Mix are calculated
using the formulas introduced in the course.

![](./report/signal_generation.png)

## Range FFT

![](./report/range_measurement.png)
To perform the range FFT the following steps are performed: 
- matrix gets transposed 
- fft function is called
- output is normalized
- absolute value is taken
- second half of the spectrum is removed

The generated output clearly shows our target.

![](./report/fig_range.png)

## Doppler FFT

The code provided with the template generated the output below which again shows our target.

![](./report/fig_range_doppler.png)

## 2D CFAR
The 2D CA CFAR implementation is following pretty exact the explanation given in the course.
As I encountered issues with re-using the same array for input and output caused by overwriting data I decided to use
a new array for the result (RES). As I initialize this array with 0 values the subsequent step to clear the value at the border
is not required in my case.
![](./report/cfar.png)

I did some experiments with the number and shape of the training cells and manage to select value which lead to relatively small detected maximum only. 
This routine yielded the following result which is located at the location of the target indicating the target's speed.

![](./report/fig_cfar.png)

I would expect that in real life finding optimal values for offset and training cells is much more of a challenge, this probably has to be updated depending on the situation.
