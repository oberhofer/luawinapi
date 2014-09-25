#------
# Load configuration
#
include config

#------
# Hopefully no need to change anything below this line
#
# INSTALL_LUACWRAP_SHARE=$(INSTALL_TOP_SHARE)/luacwrap

all clean:
	cd src; $(MAKE) $@

manual:
	cd doc; $(MAKE) $@


#------
# End of makefile
#
