#!/usr/bin/env bash

UnsealKey1=lJnqy8M4Yb48LkKGv3IVXlYcgr15AlrHke8NZGc/o6ms
UnsealKey2=+w4aNtjjaAvt0/zUXu2hT059czyGgbxnegQ3DzCoyNHq
UnsealKey3=MFHYjEWQU7thWn2xF5eytEGjI+GTxtfM79NIzy3hF8br 
UnsealKey4=EQv7NiBKR1H2ZkLjZBi/I6Yx5J+oKzDoE6E0SmVrrwn6
UnsealKey5=vmFuzD6F15KupD+Kn363AuR1aQyzR/wcXmNR/2g+XKeW

InitialRootToken=s.ZWfxRLYkkVmnmIaxAJLGBBcW

sleep 10
vault operator unseal $UnsealKey1
vault operator unseal $UnsealKey2
vault operator unseal $UnsealKey3
