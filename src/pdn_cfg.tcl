# Copyright 2020-2022 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET)} {
        lappend secondary $vdd

        set db_net [[ord::get_db_block] findNet $vdd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }

    if { $gnd != $::env(GND_NET)} {
        lappend secondary $gnd

        set db_net [[ord::get_db_block] findNet $gnd]
        if {$db_net == "NULL"} {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}


# Create a region covering the full die
set region [odb::dbRegion_create [ord::get_db_block] Die]

set die_area [[ord::get_db_block] getDieArea]
odb::dbBox_create $region [$die_area xMin] [expr [$die_area yMin] + [ord::microns_to_dbu 2.3]] [$die_area xMax] [expr [$die_area yMax] - [ord::microns_to_dbu 2.3]]

# Create voltage domain for it
set_voltage_domain -region Die -power $::env(VDD_NET) -ground $::env(GND_NET) \
    -secondary_power $secondary

# Define main PDN grid
define_pdn_grid \
    -name stdcell_grid \
    -voltage_domain Die \
    -starts_with POWER \
    -pins $::env(FP_PDN_VERTICAL_LAYER)

# Create met4 stripes
add_pdn_stripe \
    -grid stdcell_grid \
    -layer $::env(FP_PDN_VERTICAL_LAYER) \
    -width $::env(FP_PDN_VWIDTH) \
    -pitch $::env(FP_PDN_VPITCH) \
    -offset $::env(FP_PDN_VOFFSET) \
    -spacing $::env(FP_PDN_VSPACING) \
    -starts_with POWER

# Create met1 rails for standard cells
add_pdn_stripe \
    -grid stdcell_grid \
    -layer $::env(FP_PDN_RAIL_LAYER) \
    -width $::env(FP_PDN_RAIL_WIDTH) \
    -followpins \
    -starts_with POWER

# Connect rails to stripes
add_pdn_connect \
    -grid stdcell_grid \
    -layers "$::env(FP_PDN_RAIL_LAYER) $::env(FP_PDN_VERTICAL_LAYER)"

# Define default grid for macro
define_pdn_grid \
    -macro \
    -default \
    -name macro \
    -voltage_domain Die \
    -starts_with POWER \
    -halo "$::env(FP_PDN_HORIZONTAL_HALO) $::env(FP_PDN_VERTICAL_HALO)"

# Connect met3 pads on macro from met4 stripes
add_pdn_connect \
    -grid macro \
    -layers "$::env(FP_PDN_VERTICAL_LAYER) $::env(FP_PDN_HORIZONTAL_LAYER)"
