# Check if the file exists
ifeq ($(wildcard $(USER_PATH)/splitkb/rules.mk),)
    $(error The file '$(USER_PATH)/splitkb/rules.mk' does not exist. Please make sure that you have setup the halcyon modules correctly.)
endif

# Include the halcyon module rules
include $(USER_PATH)/splitkb/rules.mk
