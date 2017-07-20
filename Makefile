.PHONY: put get

put:
	cp -f ./ZZCraftExtractor.*   /Volumes/Elder\ Scrolls\ Online/live/AddOns/ZZCraftExtractor/
	cp -f ./Libs/LibLazyCrafting/* /Volumes/Elder\ Scrolls\ Online/live/AddOns/ZZCraftExtractor/Libs/LibLazyCrafting/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/ZZCraftExtractor.lua ../../SavedVariables/
	-mkdir data
	cp -f ../../SavedVariables/ZZCraftExtractor.lua data/

