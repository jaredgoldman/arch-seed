PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
NAME = arch-setup

.PHONY: install uninstall create-iso

install:
	@echo "Installing $(NAME)..."
	@mkdir -p $(BINDIR)
	@cp install/scripts/setup.sh $(BINDIR)/$(NAME)
	@chmod +x $(BINDIR)/$(NAME)
	@echo "Installation complete. You can now run '$(NAME)' from anywhere."

uninstall:
	@echo "Uninstalling $(NAME)..."
	@rm -f $(BINDIR)/$(NAME)
	@echo "Uninstallation complete."

create-iso:
	@echo "Creating Arch Linux installation ISO..."
	@mkdir -p iso
	@cp -r install iso/
	@cp install/scripts/setup.sh iso/
	@cp Makefile iso/
	@echo "ISO contents prepared in 'iso' directory"
	@echo "Use 'mkarchiso' to create the final ISO image" 