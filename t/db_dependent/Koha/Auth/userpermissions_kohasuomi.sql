INSERT INTO permissions (module, code, description) VALUES
   ( 'superlibrarian',  'superlibrarian', 'Access to all librarian functions'),
   ( 'circulate',       'circulate_remaining_permissions', 'Remaining circulation permissions'),
   ( 'circulate',       'override_renewals', 'Override blocked renewals'),
   ( 'circulate',       'overdues_report', 'Execute overdue items report'),
   ( 'circulate',       'force_checkout', 'Force checkout if a limitation exists'),
   ( 'circulate',       'manage_restrictions', 'Manage restrictions for accounts'),
   ( 'catalogue',       'staff_login', 'Allow staff login.'),
   ( 'parameters',      'parameters_remaining_permissions', 'Remaining system parameters permissions'),
   ( 'parameters',      'manage_circ_rules', 'manage circulation rules'),
   ( 'borrowers',       'view_borrowers', 'Show borrower details and search for borrowers.'),
   ( 'borrowers',       'manage_api_keys', 'Manage Borrowers\' REST API keys'),
   ( 'borrowers',       'get_self_service_status', 'Allow the user to get the self-service status of a borrower. Eg. can the borrower access self-service resources'),
   ( 'borrowers',       'get_password_reset_uuid', 'Allow the user to get password reset uuid when recovering passwords. Useful for third party service integrations that wish to do something with the uuid, such as handle emails themselves instead of Koha.'),
   ( 'permissions',     'set_permissions', 'Set user permissions'),
   ( 'reserveforothers','place_holds', 'Place holds for patrons'),
   ( 'reserveforothers','modify_holds_priority', 'Modify holds priority'),
   ( 'editcatalogue',   'add_catalogue', 'Allow adding a new bibliographic record from the REST API.'),
   ( 'editcatalogue',   'edit_catalogue', 'Edit catalog (Modify bibliographic/holdings data)'),
   ( 'editcatalogue',   'delete_catalogue', 'Allow deleting bibliographic records'),
   ( 'editcatalogue',   'fast_cataloging', 'Fast cataloging'),
   ( 'editcatalogue',   'edit_items', 'Edit items'),
   ( 'editcatalogue',   'edit_items_restricted', 'Limit item modification to subfields defined in the SubfieldsToAllowForRestrictedEditing preference (please note that edit_item is still required)'),
   ( 'editcatalogue',   'delete_all_items', 'Delete all items at once'),
   ( 'updatecharges',   'writeoff', 'Write off fines and fees'),
   ( 'updatecharges',   'remaining_permissions', 'Remaining permissions for managing fines and fees'),
   ( 'acquisition',     'vendors_manage', 'Manage vendors'),
   ( 'acquisition',     'contracts_manage', 'Manage contracts'),
   ( 'acquisition',     'period_manage', 'Manage periods'),
   ( 'acquisition',     'budget_manage', 'Manage budgets'),
   ( 'acquisition',     'budget_modify', 'Modify budget (can''t create lines, but can modify existing ones)'),
   ( 'acquisition',     'planning_manage', 'Manage budget plannings'),
   ( 'acquisition',     'order_manage', 'Manage orders & basket'),
   ( 'acquisition',     'order_manage_all', 'Manage all orders and baskets, regardless of restrictions on them'),
   ( 'acquisition',     'group_manage', 'Manage orders & basketgroups'),
   ( 'acquisition',     'order_receive', 'Manage orders & basket'),
   ( 'acquisition',     'budget_add_del', 'Add and delete budgets (but can''t modify budgets)'),
   ( 'acquisition',     'budget_manage_all', 'Manage all budgets'),
   ( 'acquisition',     'edi_manage', 'Manage EDIFACT transmissions'),
   ( 'management',      'management', 'Set library management parameters (deprecated)'),
   ( 'tools',           'edit_news', 'Write news for the OPAC and staff interfaces'),
   ( 'tools',           'label_creator', 'Create printable labels and barcodes from catalog and patron data'),
   ( 'tools',           'edit_calendar', 'Define days when the library is closed'),
   ( 'tools',           'moderate_comments', 'Moderate patron comments'),
   ( 'tools',           'edit_notices', 'Define notices'),
   ( 'tools',           'edit_notice_status_triggers', 'Set notice/status triggers for overdue items'),
   ( 'tools',           'edit_quotes', 'Edit quotes for quote-of-the-day feature'),
   ( 'tools',           'view_system_logs', 'Browse the system logs'),
   ( 'tools',           'inventory', 'Perform inventory (stocktaking) of your catalog'),
   ( 'tools',           'stage_marc_import', 'Stage MARC records into the reservoir'),
   ( 'tools',           'manage_staged_marc', 'Managed staged MARC records, including completing and reversing imports'),
   ( 'tools',           'export_catalog', 'Export bibliographic and holdings data'),
   ( 'tools',           'import_patrons', 'Import patron data'),
   ( 'tools',           'edit_patrons', 'Perform batch modification of patrons'),
   ( 'tools',           'delete_anonymize_patrons', 'Delete old borrowers and anonymize circulation history (deletes borrower reading history)'),
   ( 'tools',           'batch_upload_patron_images', 'Upload patron images in a batch or one at a time'),
   ( 'tools',           'schedule_tasks', 'Schedule tasks to run'),
   ( 'tools',           'items_batchmod', 'Perform batch modification of items'),
   ( 'tools',           'items_batchmod_restricted', 'Limit batch item modification to subfields defined in the SubfieldsToAllowForRestrictedBatchmod preference (please note that items_batchmod is still required)'),
   ( 'tools',           'items_batchdel', 'Perform batch deletion of items'),
   ( 'tools',           'manage_csv_profiles', 'Manage CSV export profiles'),
   ( 'tools',           'moderate_tags', 'Moderate patron tags'),
   ( 'tools',           'rotating_collections', 'Manage rotating collections'),
   ( 'tools',           'upload_local_cover_images', 'Upload local cover images'),
   ( 'tools',           'manage_patron_lists', 'Add, edit and delete patron lists and their contents'),
   ( 'tools',           'records_batchmod', 'Perform batch modification of records (biblios or authorities)'),
   ( 'tools',           'marc_modification_templates', 'Manage marc modification templates'),
   ( 'tools',           'records_batchdel', 'Perform batch deletion of records (bibliographic or authority)'),
   ( 'tools',           'upload_general_files', 'Upload any file'),
   ( 'tools',           'upload_manage', 'Manage uploaded files'),
   ( 'editauthorities', 'edit_authorities', 'Edit authorities'),
   ( 'serials',         'check_expiration', 'Check the expiration of a serial'),
   ( 'serials',         'claim_serials', 'Claim missing serials'),
   ( 'serials',         'create_subscription', 'Create a new subscription'),
   ( 'serials',         'delete_subscription', 'Delete an existing subscription'),
   ( 'serials',         'edit_subscription', 'Edit an existing subscription'),
   ( 'serials',         'receive_serials', 'Serials receiving'),
   ( 'serials',         'renew_subscription', 'Renew a subscription'),
   ( 'serials',         'routing', 'Routing'),
   ( 'serials',         'superserials', 'Manage subscriptions from any branch (only applies when IndependentBranches is used)'),
   ( 'reports',         'execute_reports', 'Execute SQL reports'),
   ( 'reports',         'create_reports', 'Create SQL reports'),
   ( 'reports',         'delete_reports', 'Delete SQL reports'),
   ( 'staffaccess',     'staff_access_permissions', 'Allow staff members to modify permissions for other staff members'),
   ( 'coursereserves',  'manage_courses', 'Add, edit and delete courses'),
   ( 'coursereserves',  'add_reserves', 'Add course reserves'),
   ( 'coursereserves',  'delete_reserves', 'Remove course reserves'),
   ( 'plugins',         'manage', 'Manage plugins ( install / uninstall )'),
   ( 'plugins',         'tool', 'Use tool plugins'),
   ( 'plugins',         'report', 'Use report plugins'),
   ( 'plugins',         'configure', 'Configure plugins'),
   ( 'lists',           'delete_public_lists', 'Delete public lists'),
   ( 'clubs',           'edit_templates', 'Create and update club templates'),
   ( 'clubs',           'edit_clubs', 'Create and update clubs'),
   ( 'clubs',           'enroll', 'Enroll patrons in clubs'),
   ( 'labels',          'sheets_get',                                  'Allow viewing all label sheets'),
   ( 'labels',          'sheets_new',                                  'Allow creating all label sheets'),
   ( 'labels',          'sheets_mod',                                  'Allow modifying all label sheets'),
   ( 'labels',          'sheets_del',                                  'Allow deleting all label sheets'),
   ( 'lols',            'all your base',                                  'All your base are belong to us'),
   ( 'messages',        'get_message', 'Allows to get the messages in message queue.'),
   ( 'messages',        'create_message', 'Allows to create a new message and queue it.'),
   ( 'messages',        'update_message', 'Allows to update messages in message queue.'),
   ( 'messages',        'delete_message', 'Allows to delete a message and queue it.'),
   ( 'messages',        'resend_message', 'Allows to resend messages in message queue.')
;
