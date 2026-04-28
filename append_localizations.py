import re

file_path = '/Users/suuryaprabhat/Desktop/serviceapp/lib/l10n/app_localizations.dart'

new_keys = {
    'error_prefix': 'Error:',
    'company_deleted_successfully': 'Company deleted successfully',
    'error_deleting_company': 'Error deleting company:',
    'no_companies_found': 'No companies found',
    'please_select_at_least_one_category': 'Please select at least one category',
    'please_log_in_to_update_profile': 'Please log in to update your profile',
    'profile_saved_successfully': 'Profile saved successfully!',
    'error_saving_profile': 'Error saving profile:',
    'job_seeker_profile': 'Job Seeker Profile',
    'profile_active': 'Profile Active',
    'max_categories_allowed': 'Maximum categories allowed',
    'save_profile': 'Save Profile',
    'error_fetching_job_details': 'Error fetching job details:',
    'company_information_required': 'Company Information Required',
    'add_company_info': 'Add Company Info',
    'company_id_required': 'Company ID is required for company posts',
    'please_log_in_to_update_job': 'Please log in to update a Job',
    'job_updated_successfully': 'Job updated successfully!',
    'edit_job_post': 'Edit Job Post',
    'post_type': 'Post Type',
    'post_as_company': 'Post as Company',
    'location_details': 'Location Details',
    'update_job': 'Update Job',
    'registration_successful': 'Registration successful! Please login.',
    'retry': 'Retry',
    'company_information_saved': 'Company information saved successfully!'
}

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

def replacer(match):
    # match.group(0) is `\n    },`
    addition = ""
    for k, v in new_keys.items():
        # Escape single quotes in value
        safe_v = v.replace("'", "\\'")
        addition += f"\n      '{k}': '{safe_v}',"
    return addition + match.group(0)

new_content = re.sub(r'\n    \},', replacer, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(new_content)

print("Appended successfully.")
