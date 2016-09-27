# Crazy8sBot
An IRC bot that plays the game Crazy8s, written in Swift 3 for Linux

## Description
This is the [Crazy 8s game for Swift 3](https://github.com/tachoknight/crazy8s) codebase as an IRC bot using the [C-based IRC library libircclient](http://www.ulduzsoft.com/libircclient/). 

## Purpose 
I wanted to learn how to combine Swift and C-based libraries so I thought to create an IRC bot that used the game code I'd already written so it would do something 'interesting'. I also wanted the end product to be Linux-based, so as to theoretically run on a small VM or a Raspberry Pi (once I get it compiled on there). 

## Project Layout
The project is comprised of two directories, *CIRCBot* and *Crazy8sBot*. 

###CIRCBot
This directory contains the necessary files to include the libircclient header and export it to the actual Swift code in the Crazy8sBot directory. 
###Crazy8sBot
The code is pretty much the same as the game project with the exception being ***main.swift***; this is where the IRC code is located.  

