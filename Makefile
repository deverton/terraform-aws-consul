HOSTS     := bastion consul
HOST_DIRS := $(addprefix files/,$(HOSTS))
TARGETS   := $(addsuffix /cloud-init.txt,$(HOST_DIRS))

all: $(TARGETS)

define make-goal
$1/cloud-init.txt: $(wildcard files/common/*.sh) $(wildcard $1/*.yaml) $(wildcard $1/*.sh)
endef

$(foreach hdir,$(HOST_DIRS),$(eval $(call make-goal,$(hdir))))

$(TARGETS):
	$(CURDIR)/bin/write-mime-multipart --output=$@ $^

plan: $(TARGETS)
	terraform $@

apply: $(TARGETS)
	terraform $@

destroy:
	terraform plan -destroy -out=destroy.tfplan
	terraform apply destroy.tfplan

clean:
	rm $(TARGETS)

.PHONY: all plan apply clean destroy

