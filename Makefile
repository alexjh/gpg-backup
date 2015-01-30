# GPG Backup Scheme
#
# * If printing on letter size paper, change the MONTAGE_LAYOUT to 2x2
#
# TODO:
# [ ] Change font size based on key size: 1024 bit keys cause the filenames to overlap as they're so small
#

MONTAGE_LAYOUT=4x1
SPLIT_FILES = 0 1 2 3
GPG_KEYS=$(shell gpg --list-keys --with-colons --fast-list-mode | grep pub | awk -F: '{ print $$5 }')
PRIV_OUT_BASE = $(addprefix export/, $(addsuffix -priv0, $(GPG_KEYS)))
PUB_OUT_BASE  = $(addprefix export/, $(addsuffix -pub0, $(GPG_KEYS)))
TRUST_OUT_BASE  = $(addprefix export/, $(addsuffix -trust0, $(GPG_KEYS)))
SPLIT = $(foreach var1, $(PRIV_OUT_BASE) $(PUB_OUT_BASE) $(trust_OUT_BASE), $(foreach var2, $(SPLIT_FILES), $(var1)$(var2)))
TXT = $(addsuffix .txt, $(SPLIT))
PNG = $(addsuffix .png, $(SPLIT))

FINAL_PRIV_JPG = $(addprefix export/print-priv-, $(addsuffix .jpg, $(GPG_KEYS)))
FINAL_PUB_JPG = $(addprefix export/print-pub-, $(addsuffix .jpg, $(GPG_KEYS)))
FINAL_CRED_JPG = export/print-cred.jpg

# Global silent as I'm not able to silence the rm step of intermediates
.SILENT:

.PHONY: default all
all: test_gpg_phrase test_s3 default

default: $(FINAL_PRIV_JPG) $(FINAL_PUB_JPG) $(FINAL_CRED_JPG)

-include credentials.txt

.INTERMEDIATE: $(TXT) export/credentials.png export/print-cred.png export/print-trust.txt export/print-trust.png

aspectpad:
	@echo "Download aspectpad from http://www.fmwconcepts.com/imagemagick/aspectpad/index.php"
	@/bin/false

export/%.jpg: export/%.png aspectpad
	@echo "[gen $@]"
	@./aspectpad -a 1.5 -m l -p white $< $@

export/print-cred.png: export/credentials.png export/print-trust.png
	@echo "[gen $@]"
	@montage -bordercolor black -border 5%x5% -pointsize 48 -resize 400% -geometry +80+80 -tile 2x1 -label '%f' $^ $@

export/print-pub-%.png: $(foreach filenum, $(SPLIT_FILES), export/%-pub0$(filenum).png)
	@echo "[gen $@]"
	@montage -bordercolor black -border 5%x5% -pointsize 48 -resize 400% -geometry +80+80 -tile $(MONTAGE_LAYOUT) -label '%f' $^ $@

export/print-priv-%.png: $(foreach filenum, $(SPLIT_FILES), export/%-priv0$(filenum).png)
	@echo "[gen $@]"
	@montage -bordercolor black -border 5%x5% -pointsize 96 -resize 400% -geometry +80+80 -tile $(MONTAGE_LAYOUT) -label '%f' $^ $@

export/%.png: %.txt
	@echo "[gen $@]"
	@qrencode -o $@ < $<

export/%.png: export/%.txt
	@echo "[gen $@]"
	@qrencode -o $@ < $<

$(foreach filenum, $(SPLIT_FILES), export/%0$(filenum).txt): export/%
	@echo "[gen $@]"
	@split -n 4 -d --additional-suffix=.txt $< export/$*

export/print-trust.txt:
	@echo "[gen $@]"
	@mkdir -p export
	@gpg --export-ownertrust > $@

export/%-pub:
	@echo "[gen $@]"
	@mkdir -p export
	@gpg --armor --export $* > $@

export/%-priv:
	@echo "[gen $@]"
	@mkdir -p export
	@gpg --export-secret-key $* | paperkey > $@

.PHONY: test_s3
test_s3:
	@s3cmd --access_key=$(S3_ACCESS_KEY) --secret_key=$(S3_SECRET_KEY) ls $(S3_URL) > /dev/null

.PHONY: test_gpg_phrase
test_gpg_phrase:
	@$(foreach key,$(GPG_KEYS),echo "1234" | gpg --passphrase $($(key)_PASSPHRASE) --no-use-agent -o /dev/null --local-user $(key) -as -;)

foo:
	@echo $(GPG_KEYS)
	@echo $(TXT)
	@echo $(PNG)

clean:
	rm -rf export
