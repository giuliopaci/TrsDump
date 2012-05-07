
all: trsdump

%: %.vala
	$$(head -n 1 $(<) | sed -e 's-^/[*][[:space:]]*\|[[:space:]]*[*]/$$--g') $(<)

test: trsdump
	./trsdump 2012_03_17_experiments/0022_quiz.trs

test-file: trsdump
	mkdir -p 0022_quiz-T1.5/
	./trsdump 2012_03_17_experiments/0022_quiz.trs -T 1.5 2>/dev/null | awk '{ print "0022_quiz-T1.5/0022_quiz-" NR ".wav" " " "trim" " " $$1 " " ($$2-$$1) }' | xargs -n 4 sox 2012_03_17_experiments/0022_quiz.wav
