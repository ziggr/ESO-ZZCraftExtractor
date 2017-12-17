.PHONY: put get

put:
	cp -f ./ZZCraftExtractor.*   /Volumes/Elder\ Scrolls\ Online/live/AddOns/ZZCraftExtractor/
	cp -f ./Libs/LibLazyCrafting/* /Volumes/Elder\ Scrolls\ Online/live/AddOns/ZZCraftExtractor/Libs/LibLazyCrafting/
	cp -f ./Libs/LibCraftId/* /Volumes/Elder\ Scrolls\ Online/live/AddOns/ZZCraftExtractor/Libs/LibCraftId/

get:
	cp -f /Volumes/Elder\ Scrolls\ Online/live/SavedVariables/ZZCraftExtractor.lua ../../SavedVariables/
	cp -f ../../SavedVariables/ZZCraftExtractor.lua data/

csv:
	lua ZZCraftExtractor_to_csv.lua
	cp ../../SavedVariables/ZZCraftExtractor.csv data/

setindex:
	lua ZZCraftExtractor_to_LibSetIndex.lua
	# see data/SetIndex.lua


