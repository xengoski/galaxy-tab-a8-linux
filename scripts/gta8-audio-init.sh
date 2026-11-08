#!/bin/sh
# Initialize Unisoc UMS512 sprdphone-sc2730 quad aw882xx SmartPA + Codec route
amixer -c 0 -q cset name='S_NORMAL_AP01_P_HIFI SWITCH' 1 || true
amixer -c 0 -q cset name='S_FAST_P_HIFI SWITCH' 1 || true
amixer -c 0 -q cset name='SYS_IIS1' 'vbc_iism0' || true
amixer -c 0 -q cset name='VBC_IIS_TX0_WD_SEL' 'WD_16BIT' || true
amixer -c 0 -q cset name='VBC_IIS_TX1_WD_SEL' 'WD_16BIT' || true
amixer -c 0 -q cset name='VBC_IIS_MASTER_ENALBE' 'enable' || true
amixer -c 0 -q cset name='VBC_IIS_MST_WIDTH_SET' 'WD_16BIT' || true
amixer -c 0 -q cset name='VBC_IIS_MST_SEL_0_TYPE' 'VBC_MASTER_INTERNAL' || true
amixer -c 0 -q cset name='VBC_MUX_DAC0_IIS_PORT_SEL' 'VBC_IIS_PORT_IIS0' || true
amixer -c 0 -q cset name='VBC_MUX_DAC1_IIS_PORT_SEL' 'VBC_IIS_PORT_IIS1' || true
amixer -c 0 -q cset name='VBC_MUX_IIS0_PORT_DO_SEL' 'IIS_DO_VAL_DAC0' || true
amixer -c 0 -q cset name='VBC_MUX_IIS1_PORT_DO_SEL' 'IIS_DO_VAL_DAC1' || true
amixer -c 0 -q cset name='VBC_MUX_IIS2_PORT_DO_SEL' 'IIS_DO_VAL_DAC2' || true
amixer -c 0 -q cset name='VBC_MUX_IIS3_PORT_DO_SEL' 'IIS_DO_VAL_DAC2' || true
amixer -c 0 -q cset name='VBC_MIXER0_DAC0' 'INTERCHANGE' || true
amixer -c 0 -q cset name='VBC_MIXER0_DAC1' 'INTERCHANGE' || true
amixer -c 0 -q cset name='aw_dev_0_switch' 1 || true
amixer -c 0 -q cset name='aw_dev_1_switch' 1 || true
amixer -c 0 -q cset name='aw_dev_2_switch' 1 || true
amixer -c 0 -q cset name='aw_dev_3_switch' 1 || true
# Also enable headphone DAC path in case 3.5mm jack is plugged in
amixer -c 0 -q cset name='ag_iis0_ext_sel' 'enable' || true
amixer -c 0 -q cset name='S_NORMAL_AP01_P_CODEC SWITCH' 1 || true
amixer -c 0 -q cset name='HP mix mode' 0 || true
amixer -c 0 -q cset name='HPL EAR Sel' 'HPL' || true
amixer -c 0 -q cset name='HPL Mixer DACLHPL Switch' 1 || true
amixer -c 0 -q cset name='HPR Mixer DACRHPR Switch' 1 || true
amixer -c 0 -q cset name='HPR Pin Switch' 1 || true
amixer -c 0 -q cset name='HeadPhone Function' 1 || true
amixer -c 0 -q cset name='VBC DAC0 DG Set' 80,80 || true
amixer -c 0 -q cset name='VBC DAC0 AUD MDG Set' 4096,4096 || true
exit 0
