<#
    List of API parameters of type string, that could be requested as case-insensitive or regex match
    The list is based on the swagger spec of NetBox, slightly modified to remove parameters that are not relevant for the API client

    The solution is based on a baseline list of parameters taken from v4.4.9.
    Depending on the currently connect APIs version, additional parameters are added.
    Each hastable does have two flavours of definition
    'parameter' = @()  # parameter is case-insensitive supported for all endpoints
    'parameter' = @('api/endpoint1', 'api/endpoint2')  # parameter case insitive is not supported for the endpoints in this list

    Remark for maintenance:

    If the minimum supported API version of this module should change, the baseline list must be updated to reflect the new minimum version.
    - Move any entry "<parameter> = @()" from the new minimum version to the baseline list, if it is not already present there.
      After that, let's say the new minimum version is v4.5.0, then IgnoreCase/RegexParameterV450 must only contain the parameters that do have an exception list
    - At the end of the file
      - Remove $Script:IgnoreCaseParameterDictionary['4.4'] =...
      - Remove $Script:RegexParameterDictionary['4.4'] =...
    If a new API version is released
      - a new $Script:IgnoreCaseParameterV4nn entry must be added
      - a new $Script:RegexParameterV4nn entry must be added
      - At the end of the file, add a new entry to $Script:IgnoreCaseParameterDictionary['4.nn'] = $Script:IgnoreCaseParameterBaseline + $Script:IgnoreCaseParameterV4nn
      - At the end of the file, add a new entry to $Script:RegexParameterDictionary['4.nn'] = $Script:RegexParameterBaseline + $Script:RegexParameterV4nn

    As the minimum supported API will rise beyond 4.6, in 'Setup.Tests.ps1' Context 'Query Options' the mocked data must be updated.

    There should be no maintenance required in 'Set-NBQueryOption'.
#>

# Current baseline is the API v4.4.9 list of fully supported case-insensitive parameters, which is the minimum version supported by this module
#region IgnoreCase parameter dictionary
$Script:IgnoreCaseParameterBaseline = @{
    'account'                  = @()
    'action_type'              = @()
    'app_label'                = @()
    'asset_tag'                = @()
    'auth_cipher'              = @()
    'auth_key'                 = @()
    'auth_psk'                 = @()
    'auth_type'                = @()
    'authentication_algorithm' = @()
    'authentication_method'    = @()    # 1
    'ca_file_path'             = @()
    'cid'                      = @()
    'color'                    = @()
    'description'              = @()
    'device_status'            = @()
    'dns_name'                 = @()
    'domain'                   = @()
    'duplex'                   = @()
    'email'                    = @()
    'encapsulation'            = @()    # 2
    'encryption_algorithm'     = @()
    'facility'                 = @()
    'facility_id'              = @()
    'feed_leg'                 = @()
    'file_extension'           = @()
    'file_name'                = @()
    'first_name'               = @()
    'form_factor'              = @()
    'group_name'               = @()
    'hash'                     = @()    # 3
    'http_content_type'        = @()
    'http_method'              = @()
    'key'                      = @()
    'label'                    = @()
    'last_name'                = @()
    'link'                     = @()
    'link_text'                = @()
    'link_url'                 = @()
    'mac_address'              = @()
    'mime_type'                = @()    # 4
    'mode'                     = @()
    'name'                     = @()
    'object_repr'              = @()
    'part_id'                  = @()
    'part_number'              = @()
    'path'                     = @()
    'phone'                    = @()
    'poe_mode'                 = @()
    'poe_type'                 = @()
    'pp_info'                  = @()    # 5
    'preshared_key'            = @()
    'qinq_role'                = @()
    'rd'                       = @()
    'rf_channel'               = @()
    'rf_role'                  = @()
    'secret'                   = @()
    'serial'                   = @()
    'slug'                     = @()
    'source_url'               = @()
    'ssid'                     = @()    # 6
    'status'                   = @()
    'table'                    = @()
    'time_zone'                = @()
    'title'                    = @()
    'user_name'                = @()
    'username'                 = @()
    'validation_regex'         = @()
    'wwn'                      = @()
    'xconnect_id'              = @()    # 69
}

$Script:IgnoreCaseParameterV449 = @{
    # v4.4.9 existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'     = @('api/ipam/ip-addresses/')
    'kind'        = @('api/dcim/interfaces/')
    'model'       = @('api/dcim/devices/')
    'object_type' = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'    = @('api/dcim/devices/')
    'protocol'    = @('api/ipam/service-templates/', 'api/ipam/services/')
    'role'        = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'  = @('api/ipam/ip-addresses/')
    'type'        = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/dcim/console-port-templates/', 'api/dcim/console-server-port-templates/', 'api/dcim/power-feeds/', 'api/dcim/power-outlet-templates/', 'api/dcim/power-port-templates/', 'api/virtualization/clusters/')
}
$Script:IgnoreCaseParameterV450 = @{
    # v4.4.9 -> v4.5.0, these parameters are case-insensitive for all endpoints
    'action'         = @()      # 70
    'airflow'        = @()
    'base_choices'   = @()
    'button_class'   = @()
    'cable_end'      = @()
    'distance_unit'  = @()
    'face'           = @()
    'filter_logic'   = @()
    'length_unit'    = @()
    'outer_unit'     = @()
    'phase'          = @()      # 80
    'protocol'       = @()
    'queue_name'     = @()
    'start_on_boot'  = @()
    'subdevice_role' = @()
    'supply'         = @()
    'term_side'      = @()
    'ui_editable'    = @()
    'ui_visible'     = @()
    'weight_unit'    = @()      # 89
    # existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'        = @('api/ipam/ip-addresses/')
    'kind'           = @('api/dcim/interfaces/')
    'model'          = @('api/dcim/devices/')
    'object_type'    = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'       = @('api/dcim/devices/')
    'priority'       = @('api/ipam/fhrp-group-assignments/')
    'profile'        = @('api/dcim/module-types/', 'api/dcim/modules/', 'api/extras/config-contexts/')
    'role'           = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'     = @('api/ipam/ip-addresses/')
    'type'           = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/virtualization/clusters/')
}
$Script:IgnoreCaseParameterV461 = @{
    # v4.4.9 -> v4.6.1, these parameters are case-insensitive for all endpoints
    'action'         = @()
    'airflow'        = @()
    'base_choices'   = @()
    'button_class'   = @()
    'cable_end'      = @()
    'distance_unit'  = @()
    'face'           = @()
    'filter_logic'   = @()
    'length_unit'    = @()
    'notifications'  = @()      # new in 4.6.1, not present in 4.5.0
    'outer_unit'     = @()
    'phase'          = @()
    'protocol'       = @()
    'queue_name'     = @()
    'start_on_boot'  = @()
    'subdevice_role' = @()
    'supply'         = @()
    'term_side'      = @()
    'ui_editable'    = @()
    'ui_visible'     = @()
    'weight_unit'    = @()
    # existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'        = @('api/ipam/ip-addresses/')
    'kind'           = @('api/dcim/interfaces/')
    'model'          = @('api/dcim/devices/')
    'object_type'    = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'       = @('api/dcim/devices/')
    'priority'       = @('api/ipam/fhrp-group-assignments/')
    'profile'        = @('api/dcim/module-types/', 'api/dcim/modules/', 'api/extras/config-contexts/')
    'role'           = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/asns/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'     = @('api/ipam/ip-addresses/')
    'type'           = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/virtualization/clusters/')
}
$Script:IgnoreCaseParameterV470 = @{
    # v4.4.9 -> v4.7.0, these parameters are case-insensitive for all endpoints
    'action'         = @()
    'airflow'        = @()
    'base_choices'   = @()
    'button_class'   = @()
    'cable_end'      = @()
    'cooling_capability' = @()  # new in 4.7.0 (racks, rack-types)
    'cooling_method' = @()      # new in 4.7.0 (devices, device-types, module-types)
    'diameter_unit'  = @()      # new in 4.7.0 (cooling intakes/outflows + templates)
    'distance_unit'  = @()
    'face'           = @()
    'filter_logic'   = @()
    'fluid_type'     = @()      # new in 4.7.0 (cooling sources)
    'length_unit'    = @()
    'max_flow_unit'  = @()      # new in 4.7.0 (cooling feeds)
    'notifications'  = @()      # new in 4.6.1, not present in 4.5.0
    'outer_unit'     = @()
    'phase'          = @()
    'protocol'       = @('api/ipam/service-templates/', 'api/ipam/services/')   # 4.7: method filter over port_mappings, only __n left
    'queue_name'     = @()
    'start_on_boot'  = @()
    'subdevice_role' = @()
    'supply'         = @()
    'term_side'      = @()
    'ui_editable'    = @()
    'ui_visible'     = @()
    'weight_unit'    = @()
    # existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'        = @('api/ipam/ip-addresses/')
    'kind'           = @('api/dcim/interfaces/')
    'model'          = @('api/dcim/devices/')
    'object_type'    = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'       = @('api/dcim/devices/')
    'priority'       = @('api/ipam/fhrp-group-assignments/')
    'profile'        = @('api/dcim/module-types/', 'api/dcim/modules/', 'api/extras/config-contexts/')
    'role'           = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/asns/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'     = @('api/ipam/ip-addresses/')
    'type'           = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/virtualization/clusters/')
}
#endregion

#region Regex parameter dictionary
$Script:RegexParameterBaseline = @{
    'account'                  = @()
    'action_type'              = @()
    'app_label'                = @()
    'asset_tag'                = @()
    'auth_cipher'              = @()
    'auth_key'                 = @()
    'auth_psk'                 = @()
    'auth_type'                = @()
    'authentication_algorithm' = @()
    'authentication_method'    = @()    # 1
    'ca_file_path'             = @()
    'cid'                      = @()
    'color'                    = @()
    'description'              = @()
    'device_status'            = @()
    'dns_name'                 = @()
    'domain'                   = @()
    'duplex'                   = @()
    'email'                    = @()
    'encapsulation'            = @()    # 2
    'encryption_algorithm'     = @()
    'facility'                 = @()
    'facility_id'              = @()
    'feed_leg'                 = @()
    'file_extension'           = @()
    'file_name'                = @()
    'first_name'               = @()
    'form_factor'              = @()
    'group_name'               = @()
    'hash'                     = @()    # 3
    'http_content_type'        = @()
    'http_method'              = @()
    'key'                      = @()
    'label'                    = @()
    'last_name'                = @()
    'link'                     = @()
    'link_text'                = @()
    'link_url'                 = @()
    'mac_address'              = @()
    'mime_type'                = @()    # 4
    'mode'                     = @()
    'name'                     = @()
    'object_repr'              = @()
    'part_id'                  = @()
    'part_number'              = @()
    'path'                     = @()
    'phone'                    = @()
    'poe_mode'                 = @()
    'poe_type'                 = @()
    'pp_info'                  = @()    # 5
    'preshared_key'            = @()
    'qinq_role'                = @()
    'rd'                       = @()
    'rf_channel'               = @()
    'rf_role'                  = @()
    'secret'                   = @()
    'serial'                   = @()
    'slug'                     = @()
    'source_url'               = @()
    'ssid'                     = @()    # 6
    'status'                   = @()
    'table'                    = @()
    'time_zone'                = @()
    'title'                    = @()
    'user_name'                = @()
    'username'                 = @()
    'validation_regex'         = @()
    'wwn'                      = @()
    'xconnect_id'              = @()    # 69
}

$Script:RegexParameterV449 = @{
    # v4.4.9 existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'     = @('api/ipam/ip-addresses/')
    'kind'        = @('api/dcim/interfaces/')
    'model'       = @('api/dcim/devices/')
    'object_type' = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'    = @('api/dcim/devices/')
    'protocol'    = @('api/ipam/service-templates/', 'api/ipam/services/')
    'role'        = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'  = @('api/ipam/ip-addresses/')
    'type'        = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/dcim/console-port-templates/', 'api/dcim/console-server-port-templates/', 'api/dcim/power-feeds/', 'api/dcim/power-outlet-templates/', 'api/dcim/power-port-templates/', 'api/virtualization/clusters/')
}
$Script:RegexParameterV450 = @{
    # v4.4.9 -> v4.5.0, these parameters are case-insensitive for all endpoints
    'action'         = @()      # 70
    'airflow'        = @()
    'base_choices'   = @()
    'button_class'   = @()
    'cable_end'      = @()
    'distance_unit'  = @()
    'face'           = @()
    'filter_logic'   = @()
    'length_unit'    = @()
    'outer_unit'     = @()
    'phase'          = @()      # 80
    'protocol'       = @()
    'queue_name'     = @()
    'start_on_boot'  = @()
    'subdevice_role' = @()
    'supply'         = @()
    'term_side'      = @()
    'ui_editable'    = @()
    'ui_visible'     = @()
    'weight_unit'    = @()      # 89
    # existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'        = @('api/ipam/ip-addresses/')
    'kind'           = @('api/dcim/interfaces/')
    'model'          = @('api/dcim/devices/')
    'object_type'    = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'       = @('api/dcim/devices/')
    'priority'       = @('api/ipam/fhrp-group-assignments/')
    'profile'        = @('api/dcim/module-types/', 'api/dcim/modules/', 'api/extras/config-contexts/')
    'role'           = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'     = @('api/ipam/ip-addresses/')
    'type'           = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/virtualization/clusters/')
}
$Script:RegexParameterV461 = @{
    # v4.4.9 -> v4.6.1, these parameters are case-insensitive for all endpoints
    'action'         = @()
    'airflow'        = @()
    'base_choices'   = @()
    'button_class'   = @()
    'cable_end'      = @()
    'distance_unit'  = @()
    'face'           = @()
    'filter_logic'   = @()
    'length_unit'    = @()
    'notifications'  = @()      # new in 4.6.1, not present in 4.5.0
    'outer_unit'     = @()
    'phase'          = @()
    'protocol'       = @()
    'queue_name'     = @()
    'start_on_boot'  = @()
    'subdevice_role' = @()
    'supply'         = @()
    'term_side'      = @()
    'ui_editable'    = @()
    'ui_visible'     = @()
    'weight_unit'    = @()
    # existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'        = @('api/ipam/ip-addresses/')
    'kind'           = @('api/dcim/interfaces/')
    'model'          = @('api/dcim/devices/')
    'object_type'    = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'       = @('api/dcim/devices/')
    'priority'       = @('api/ipam/fhrp-group-assignments/')
    'profile'        = @('api/dcim/module-types/', 'api/dcim/modules/', 'api/extras/config-contexts/')
    'role'           = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/asns/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'     = @('api/ipam/ip-addresses/')
    'type'           = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/virtualization/clusters/')
}
$Script:RegexParameterV470 = @{
    # v4.4.9 -> v4.7.0, these parameters are case-insensitive for all endpoints
    'action'         = @()
    'airflow'        = @()
    'base_choices'   = @()
    'button_class'   = @()
    'cable_end'      = @()
    'cooling_capability' = @()  # new in 4.7.0 (racks, rack-types)
    'cooling_method' = @()      # new in 4.7.0 (devices, device-types, module-types)
    'diameter_unit'  = @()      # new in 4.7.0 (cooling intakes/outflows + templates)
    'distance_unit'  = @()
    'face'           = @()
    'filter_logic'   = @()
    'fluid_type'     = @()      # new in 4.7.0 (cooling sources)
    'length_unit'    = @()
    'max_flow_unit'  = @()      # new in 4.7.0 (cooling feeds)
    'notifications'  = @()      # new in 4.6.1, not present in 4.5.0
    'outer_unit'     = @()
    'phase'          = @()
    'protocol'       = @('api/ipam/service-templates/', 'api/ipam/services/')   # 4.7: method filter over port_mappings, only __n left
    'queue_name'     = @()
    'start_on_boot'  = @()
    'subdevice_role' = @()
    'supply'         = @()
    'term_side'      = @()
    'ui_editable'    = @()
    'ui_visible'     = @()
    'weight_unit'    = @()
    # existing parameters that are case-insensitive, exceptions for endpoints are listed in the arrays
    'address'        = @('api/ipam/ip-addresses/')
    'kind'           = @('api/dcim/interfaces/')
    'model'          = @('api/dcim/devices/')
    'object_type'    = @('api/core/jobs/', 'api/extras/bookmarks/', 'api/extras/image-attachments/', 'api/extras/table-configs/', 'api/extras/tagged-objects/', 'api/tenancy/contact-assignments/')
    'position'       = @('api/dcim/devices/')
    'priority'       = @('api/ipam/fhrp-group-assignments/')
    'profile'        = @('api/dcim/module-types/', 'api/dcim/modules/', 'api/extras/config-contexts/')
    'role'           = @('api/dcim/devices/', 'api/dcim/inventory-item-templates/', 'api/dcim/inventory-items/', 'api/dcim/racks/', 'api/ipam/asns/', 'api/ipam/ip-ranges/', 'api/ipam/prefixes/', 'api/ipam/vlans/', 'api/tenancy/contact-assignments/', 'api/virtualization/virtual-machines/')
    'service_id'     = @('api/ipam/ip-addresses/')
    'type'           = @('api/circuits/circuits/', 'api/circuits/virtual-circuits/', 'api/virtualization/clusters/')
}
#endregion

# Set-NBQueryOption will set this to whatever is appropriate for the API version
# default is to start with case insensitive
$Script:QueryParameterDecoration = ''       # valid values are '', '__ie', '__regex', '__iregex'
$Script:QueryParameterHash = @{}
# This will contain the collection of all case-insensitive parameters per known API version, including any exceptions for specific endpoints
# Keep it orderd so that we can easily find the first and last known versions
$Script:IgnoreCaseParameterDictionary  = [ordered]@{}
$Script:IgnoreCaseParameterDictionary['4.4'] = $Script:IgnoreCaseParameterBaseline + $Script:IgnoreCaseParameterV449
$Script:IgnoreCaseParameterDictionary['4.5'] = $Script:IgnoreCaseParameterBaseline + $Script:IgnoreCaseParameterV450
$Script:IgnoreCaseParameterDictionary['4.6'] = $Script:IgnoreCaseParameterBaseline + $Script:IgnoreCaseParameterV461
$Script:IgnoreCaseParameterDictionary['4.7'] = $Script:IgnoreCaseParameterBaseline + $Script:IgnoreCaseParameterV470

$Script:RegexParameterDictionary  = [ordered]@{}
$Script:RegexParameterDictionary['4.4'] = $Script:RegexParameterBaseline + $Script:RegexParameterV449
$Script:RegexParameterDictionary['4.5'] = $Script:RegexParameterBaseline + $Script:RegexParameterV450
$Script:RegexParameterDictionary['4.6'] = $Script:RegexParameterBaseline + $Script:RegexParameterV461
$Script:RegexParameterDictionary['4.7'] = $Script:RegexParameterBaseline + $Script:RegexParameterV470
