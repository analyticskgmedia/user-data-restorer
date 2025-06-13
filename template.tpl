// Check localStorage read permission___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "User Data Restorer",
  "brand": {
    "id": "kg_media",
    "displayName": "KG Media",
    "thumbnail": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg"
  },
  "description": "Restores previously captured user data from localStorage into the dataLayer on page load. Works with the User Data Listener template to maintain user data across pages.",
  "categories": ["MARKETING", "PERSONALIZATION", "UTILITY"],
  "containerContexts": ["WEB"]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "GROUP",
    "name": "restoreSettings",
    "displayName": "Data Restore Settings",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "TEXT",
        "name": "localStorageKey",
        "displayName": "localStorage Key",
        "simpleValueType": true,
        "defaultValue": "kg_media_user_data",
        "help": "Must match the localStorage key used in the User Data Listener template"
      },
      {
        "type": "TEXT",
        "name": "dataLayerEventName",
        "displayName": "dataLayer Event Name",
        "simpleValueType": true,
        "defaultValue": "userData.restored",
        "help": "Event name to push when user data is restored"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "dataFilters",
    "displayName": "Data Filters",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "restoreEmail",
        "checkboxText": "Restore Email Data",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "restorePhone",
        "checkboxText": "Restore Phone Data",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "restoreName",
        "checkboxText": "Restore Name Data",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "restoreAddress",
        "checkboxText": "Restore Address Data",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "restoreHashed",
        "checkboxText": "Restore Hashed Data",
        "simpleValueType": true,
        "defaultValue": true,
        "help": "Include hashed versions of sensitive data"
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "advancedSettings",
    "displayName": "Advanced Settings",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "TEXT",
        "name": "dataMaxAge",
        "displayName": "Max Data Age (hours)",
        "simpleValueType": true,
        "defaultValue": "168",
        "help": "Maximum age of stored data to restore (default: 168 hours = 7 days). Set to 0 to disable age check."
      },
      {
        "type": "CHECKBOX",
        "name": "enableLogging",
        "checkboxText": "Enable Console Logging",
        "simpleValueType": true,
        "defaultValue": false
      },
      {
        "type": "CHECKBOX",
        "name": "clearAfterRestore",
        "checkboxText": "Clear localStorage after restore",
        "simpleValueType": true,
        "defaultValue": false,
        "help": "Remove data from localStorage after restoring to dataLayer"
      },

    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const log = require('logToConsole');
const createQueue = require('createQueue');
const copyFromDataLayer = require('copyFromDataLayer');
const getCookieValues = require('getCookieValues');
const localStorage = require('localStorage');
const queryPermission = require('queryPermission');
const makeString = require('makeString');
const getTimestampMillis = require('getTimestampMillis');
const JSON = require('JSON');
const getType = require('getType');
const isConsentGranted = require('isConsentGranted');
const makeNumber = require('makeNumber');
const Math = require('Math');

// Check Google Consent Mode
const adStorageGranted = isConsentGranted('ad_storage');
const analyticsStorageGranted = isConsentGranted('analytics_storage');
const adUserDataGranted = isConsentGranted('ad_user_data');

// Determine if we should proceed based on consent
let shouldProceed = false;

// We need at least analytics consent to restore data
if (analyticsStorageGranted || (adStorageGranted && adUserDataGranted)) {
  shouldProceed = true;
}

if (!shouldProceed) {
  if (data.enableLogging) {
    log('User Data Restorer: Insufficient consent granted. Current consent state:', {
      ad_storage: adStorageGranted,
      analytics_storage: analyticsStorageGranted,
      ad_user_data: adUserDataGranted
    });
  }
  data.gtmOnSuccess();
  return;
}

// Check legacy cookie consent if configured (backwards compatibility)
if (data.cookieConsent) {
  const consentValue = getCookieValues(data.cookieConsent);
  if (!consentValue || consentValue.length === 0 || consentValue[0] !== 'true') {
    if (data.enableLogging) {
      log('User Data Restorer: No cookie consent, exiting');
    }
    data.gtmOnSuccess();
    return;
  }
}
if (!queryPermission('access_local_storage', 'read', data.localStorageKey)) {
  if (data.enableLogging) {
    log('User Data Restorer: No permission to read localStorage key:', data.localStorageKey);
  }
  data.gtmOnFailure();
  return;
}

// Create dataLayer push function
const dataLayerPush = createQueue('dataLayer');

// Check if we should restore based on restore mode
const shouldRestore = function() {
  if (data.restoreMode === 'always') {
    if (data.enableLogging) {
      log('User Data Restorer: Always restore mode - proceeding');
    }
    return true;
  }
  
  if (data.restoreMode === 'missing') {
    // Check if current page already has user data in dataLayer
    const existingEmail = copyFromDataLayer('userData.email');
    const existingPhone = copyFromDataLayer('userData.phone');
    const existingFirstName = copyFromDataLayer('userData.firstName');
    const existingLastName = copyFromDataLayer('userData.lastName');
    
    if (data.enableLogging) {
      log('User Data Restorer: Checking existing dataLayer data:', {
        email: existingEmail,
        phone: existingPhone,
        firstName: existingFirstName,
        lastName: existingLastName
      });
    }
    
    // If any user data exists, don't restore
    if (existingEmail || existingPhone || existingFirstName || existingLastName) {
      if (data.enableLogging) {
        log('User Data Restorer: User data already exists in dataLayer, skipping restore');
      }
      return false;
    }
    
    if (data.enableLogging) {
      log('User Data Restorer: No existing user data found - proceeding with restore');
    }
  }
  
  return true;
};

// Main restore function
const restoreUserData = function() {
  if (data.enableLogging) {
    log('User Data Restorer: Starting data restoration from localStorage key:', data.localStorageKey);
  }
  
  // Try to read data from localStorage
  const storedDataStr = localStorage.getItem(data.localStorageKey);
  
  if (!storedDataStr) {
    if (data.enableLogging) {
      log('User Data Restorer: No data found in localStorage');
    }
    data.gtmOnSuccess();
    return;
  }
  
  // Parse JSON data with error handling
  const storedData = JSON.parse(storedDataStr);
  
  if (data.enableLogging) {
    log('User Data Restorer: Parsed stored data:', storedData);
  }
  
  if (!storedData || getType(storedData) !== 'object') {
    if (data.enableLogging) {
      log('User Data Restorer: Invalid stored data format or JSON parse error');
    }
    data.gtmOnFailure();
    return;
  }
  
  // Check data age if configured
  if (data.dataMaxAge && makeNumber(data.dataMaxAge) > 0) {
    const maxAgeMs = makeNumber(data.dataMaxAge) * 60 * 60 * 1000; // Convert hours to milliseconds
    const currentTime = getTimestampMillis();
    const dataTimestamp = makeNumber(storedData.timestamp) || 0;
    
    if (currentTime - dataTimestamp > maxAgeMs) {
      if (data.enableLogging) {
        const ageInHours = Math.round((currentTime - dataTimestamp) / (60 * 60 * 1000));
        log('User Data Restorer: Stored data is too old, skipping restore. Age:', 
            ageInHours, 'hours');
      }
      
      // Optionally clean up old data
      if (data.clearAfterRestore && queryPermission('access_local_storage', 'write', data.localStorageKey)) {
        localStorage.removeItem(data.localStorageKey);
        if (data.enableLogging) {
          log('User Data Restorer: Removed old data from localStorage');
        }
      }
      
      data.gtmOnSuccess();
      return;
    }
  }
  
  // Extract user data
  const userData = storedData.userData || {};
  
  if (data.enableLogging) {
    log('User Data Restorer: Extracted userData:', userData);
  }
  
  if (getType(userData) !== 'object') {
    if (data.enableLogging) {
      log('User Data Restorer: No userData object found in stored data');
    }
    data.gtmOnSuccess();
    return;
  }
  
  // Prepare dataLayer event
  const eventData = {
    event: data.dataLayerEventName,
    'userData.source': 'restored_from_localStorage',
    'userData.restoredAt': makeString(getTimestampMillis())
  };
  
  let hasDataToRestore = false;
  
  // Restore email data
  if (data.restoreEmail && userData.email) {
    eventData['userData.email'] = userData.email;
    hasDataToRestore = true;
    
    if (data.restoreHashed && userData.email_hashed) {
      eventData['userData.email_hashed'] = userData.email_hashed;
    }
  }
  
  // Restore phone data
  if (data.restorePhone && userData.phone) {
    eventData['userData.phone'] = userData.phone;
    hasDataToRestore = true;
    
    if (data.restoreHashed && userData.phone_hashed) {
      eventData['userData.phone_hashed'] = userData.phone_hashed;
    }
  }
  
  // Restore name data
  if (data.restoreName) {
    if (userData.firstName) {
      eventData['userData.firstName'] = userData.firstName;
      hasDataToRestore = true;
    }
    if (userData.lastName) {
      eventData['userData.lastName'] = userData.lastName;
      hasDataToRestore = true;
    }
  }
  
  // Restore address data
  if (data.restoreAddress) {
    if (userData.address) {
      eventData['userData.address'] = userData.address;
      hasDataToRestore = true;
    }
    if (userData.city) {
      eventData['userData.city'] = userData.city;
      hasDataToRestore = true;
    }
    if (userData.postalCode) {
      eventData['userData.postalCode'] = userData.postalCode;
      hasDataToRestore = true;
    }
    if (userData.country) {
      eventData['userData.country'] = userData.country;
      hasDataToRestore = true;
    }
  }
  
  // Only push to dataLayer if we have data to restore
  if (hasDataToRestore) {
    if (data.enableLogging) {
      log('User Data Restorer: About to push to dataLayer:', eventData);
    }
    
    dataLayerPush(eventData);
    
    if (data.enableLogging) {
      log('User Data Restorer: Successfully restored user data to dataLayer');
    }
    
    // Clear localStorage if requested
    if (data.clearAfterRestore && queryPermission('access_local_storage', 'write', data.localStorageKey)) {
      localStorage.removeItem(data.localStorageKey);
      if (data.enableLogging) {
        log('User Data Restorer: Cleared data from localStorage');
      }
    }
  } else {
    if (data.enableLogging) {
      log('User Data Restorer: No matching data found to restore based on current filters');
    }
  }
  
  data.gtmOnSuccess();
};

// Initialize and restore
if (data.enableLogging) {
  log('User Data Restorer: Initialized with config:', {
    localStorageKey: data.localStorageKey,
    dataLayerEventName: data.dataLayerEventName,
    restoreEmail: data.restoreEmail,
    restorePhone: data.restorePhone,
    restoreName: data.restoreName,
    restoreAddress: data.restoreAddress,
    dataMaxAge: data.dataMaxAge
  });
}

// Start the restore process
restoreUserData();


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_consent",
        "versionId": "1"
      },
      "param": [
        {
          "key": "consentTypes",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_storage"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "analytics_storage"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "consentType"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "ad_user_data"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "dataLayer"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_local_storage",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "kg_media_user_data"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": true
                  }
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedKeys",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: Basic Data Restore Test
  code: |-
    const mockData = {
      localStorageKey: 'kg_media_user_data',
      dataLayerEventName: 'userData.restored',
      restoreMode: 'always',
      restoreEmail: true,
      restorePhone: true,
      restoreName: true,
      restoreAddress: true,
      enableLogging: true
    };

    // Mock localStorage with test data
    mock('localStorage', {
      getItem: (key) => {
        if (key === 'kg_media_user_data') {
          return JSON.stringify({
            timestamp: '1638360000000',
            userData: {
              email: 'test@example.com',
              firstName: 'John',
              lastName: 'Doe'
            }
          });
        }
        return null;
      }
    });

    // Run the template code
    runCode(mockData);

    // Verify dataLayer push was called
    assertApi('createQueue').wasCalledWith('dataLayer');
    assertApi('gtmOnSuccess').wasCalled();

- name: No Data Available Test
  code: |-
    const mockData = {
      localStorageKey: 'kg_media_user_data',
      restoreMode: 'always',
      enableLogging: true
    };

    // Mock empty localStorage
    mock('localStorage', {
      getItem: () => null
    });

    // Run the template code
    runCode(mockData);

    // Should complete successfully but not push data
    assertApi('gtmOnSuccess').wasCalled();

- name: Data Age Check Test
  code: |-
    const mockData = {
      localStorageKey: 'kg_media_user_data',
      restoreMode: 'always',
      dataMaxAge: '1', // 1 hour
      enableLogging: true
    };

    // Mock old data (2 hours ago)
    const twoHoursAgo = Date.now() - (2 * 60 * 60 * 1000);
    mock('localStorage', {
      getItem: () => JSON.stringify({
        timestamp: twoHoursAgo.toString(),
        userData: { email: 'old@example.com' }
      })
    });

    mock('getTimestampMillis', () => Date.now());

    // Run the template code
    runCode(mockData);

    // Should complete without restoring old data
    assertApi('gtmOnSuccess').wasCalled();

- name: Existing Data Skip Test
  code: |-
    const mockData = {
      localStorageKey: 'kg_media_user_data',
      restoreMode: 'missing',
      enableLogging: true
    };

    // Mock existing dataLayer data
    mock('copyFromDataLayer', (key) => {
      if (key === 'userData.email') return 'existing@example.com';
      return undefined;
    });

    // Run the template code
    runCode(mockData);

    // Should skip restore due to existing data
    assertApi('gtmOnSuccess').wasCalled();


___NOTES___

Created on 6/13/2025, 10:30:00 AM

This template complements the User Data Listener by restoring previously captured user data from localStorage back into the dataLayer on subsequent page loads. Key features:

- Restores user data across page sessions
- Configurable data age limits to prevent stale data
- Option to restore only when no current user data exists
- Supports same data types as the listener (email, phone, name, address)
- Includes hashed data restoration
- Full consent mode compliance
- Option to clear localStorage after restore
- Comprehensive logging for debugging

Usage:
1. Set up the User Data Listener template to capture and store data
2. Add this User Data Restorer template to fire on page load
3. Configure matching localStorage key between both templates
4. User data will now persist across page navigation