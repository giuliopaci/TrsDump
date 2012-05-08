BASE_INPUT_PATH=./
BASE_OUTPUT_PATH=output/

INPUT_TRS_FILES=\

OUTPUT_PROMPTS_FILES:=\
	$(addprefix $(BASE_OUTPUT_PATH)answers/, $(INPUT_TRS_FILES:.trs=/prompts.txt)) \
	$(addprefix $(BASE_OUTPUT_PATH)questions/, $(INPUT_TRS_FILES:.trs=/prompts.txt)) \
	$(addprefix $(BASE_OUTPUT_PATH)speech/, $(INPUT_TRS_FILES:.trs=/prompts.txt))

OUTPUT_LIST_FILES:= $(OUTPUT_PROMPTS_FILES:prompts.txt=list.txt)



all: trsdump $(OUTPUT_PROMPTS_FILES) $(OUTPUT_LIST_FILES)

%: %.vala
	$$(head -n 1 $(<) | sed -e 's-^/[*][[:space:]]*\|[[:space:]]*[*]/$$--g') $(<)

%/list.txt: %/prompts.txt
	cat $(<) \
		| awk '{ printf "%05d.wav\n", NR }' \
		> $(@)

$(BASE_OUTPUT_PATH)answers/%/prompts.txt: $(BASE_INPUT_PATH)%.trs
	mkdir -p $(shell dirname $(@))
	./trsdump $(<) \
		-T 1.5 \
		-X '<robot_moves>' \
		-X '<robot_speaks>' \
		-X '<garbage>' \
		-X '<laughter>' \
		-X '<breath>' \
		-X '<tongueclick>' \
		-E '<whispered>' \
		-I 'alize.answer' > $(@) 2> /dev/null
	cat $(@) \
		| awk '{ printf "%s%05d.wav trim %f %f ", "$(shell dirname $(@))/", NR, $$1, ($$2-$$1) }' \
		| xargs -n 4 sox $(<:.trs=.wav)
	cut $(@) --fields=3- -d " " \
		| awk '{ outfile = sprintf("%s%05d.txt", "$(shell dirname $(@))/", NR) ; print > outfile }'

$(BASE_OUTPUT_PATH)questions/%/prompts.txt: $(BASE_INPUT_PATH)%.trs
	mkdir -p $(shell dirname $(@))
	./trsdump $(<) \
		-T 1.5 \
		-X '<robot_moves>' \
		-X '<robot_speaks>' \
		-X '<garbage>' \
		-X '<laughter>' \
		-X '<breath>' \
		-X '<tongueclick>' \
		-E '<whispered>' \
		-I 'alize.question' > $(@) 2> /dev/null
	cat $(@) \
		| awk '{ printf "%s%05d.wav trim %f %f ", "$(shell dirname $(@))/", NR, $$1, ($$2-$$1) }' \
		| xargs -n 4 sox $(<:.trs=.wav)
	cut $(@) --fields=3- -d " " \
		| awk '{ outfile = sprintf("%s%05d.txt", "$(shell dirname $(@))/", NR) ; print > outfile }'

$(BASE_OUTPUT_PATH)speech/%/prompts.txt: $(BASE_INPUT_PATH)%.trs
	mkdir -p $(shell dirname $(@))
	./trsdump $(<) \
		-T 1.5 \
		-X '<robot_moves>' \
		-X '<robot_speaks>' \
		-X '<garbage>' \
		-X '<laughter>' \
		-X '<breath>' \
		-X '<tongueclick>' \
		-E '<whispered>' > $(@) 2> /dev/null
	cat $(@) \
		| awk '{ printf "%s%05d.wav trim %f %f ", "$(shell dirname $(@))/", NR, $$1, ($$2-$$1) }' \
		| xargs -n 4 sox $(<:.trs=.wav)
	cut $(@) --fields=3- -d " " \
		| awk '{ outfile = sprintf("%s%05d.txt", "$(shell dirname $(@))/", NR) ; print > outfile }'

.DELETE_ON_ERROR: