# GTM User Data Restorer - Cross-Page Data Persistence

A powerful Google Tag Manager template that restores previously captured user data from localStorage into the dataLayer on page load. Works seamlessly with the User Data Listener to maintain user information across page navigation and sessions.

## Features

- ✅ **Cross-Page Persistence** - User data available on every page after initial capture
- ✅ **Smart Data Restoration** - Automatically restores stored user data to dataLayer
- ✅ **Age-Based Validation** - Configurable data expiration to prevent stale data
- ✅ **Selective Restoration** - Choose which data types to restore
- ✅ **GDPR Compliance** - Full Google Consent Mode v2 integration
- ✅ **Comprehensive Logging** - Detailed debugging information
- ✅ **Performance Optimized** - Minimal impact on page load speed

## Installation

### 1. Upload the Template to GTM

1. Download the template file: `template.tpl`
2. In GTM, go to **Templates** → **Tag Templates** → **New**
3. Click the three dots menu → **Import**
4. Select the template file and import it

### 2. Create a New Tag

1. Go to **Tags** → **New**
2. Choose your imported "User Data Restorer" template
3. Configure the settings (see below)
4. Set trigger to "Page View - All Pages" or "DOM Ready - All Pages"
5. **Important**: Set high tag priority (e.g., 100) or use tag sequencing
6. Save and publish

## Configuration

### Data Restore Settings

- **localStorage Key**: Must match the key used in User Data Listener (default: `kg_media_user_data`)
- **dataLayer Event Name**: Custom event name when data is restored (default: `userData.restored`)

### Data Filters

- **Restore Email Data**: Include email and email_hashed in restoration
- **Restore Phone Data**: Include phone and phone_hashed in restoration  
- **Restore Name Data**: Include firstName and lastName in restoration
- **Restore Address Data**: Include address, city, postalCode, country in restoration
- **Restore Hashed Data**: Include hashed versions of sensitive data

### Advanced Settings

- **Max Data Age (hours)**: Maximum age of stored data to restore (default: 168 hours = 7 days)
- **Enable Console Logging**: Detailed debugging information
- **Clear localStorage after restore**: Remove data from storage after restoring (optional)

## Tag Sequencing Setup

To ensure user data is available before other tags fire:

### Method 1: Tag Priority (Recommended)
1. Set **User Data Restorer** priority to `100`
2. Set other tags priority to `50` or lower
3. Use "DOM Ready" trigger for earliest execution

### Method 2: Tag Sequencing
1. In your conversion/analytics tags, go to **Advanced Settings**
2. **Tag Sequencing** → **Setup Tag** → Select "User Data Restorer"

## Data Flow Example

### User Journey Across Pages

**Page A (Contact Form):**
```
1. User fills contact form
2. User Data Listener captures: firstName, lastName, email, phone
3. Data stored in localStorage with timestamp
```

**Page B (Product Page):**
```
1. Page loads with empty dataLayer
2. User Data Restorer runs first (high priority)
3. Reads localStorage → Finds user data
4. Pushes to dataLayer: userData.restored event
5. Other tags fire → User data now available
```

**Page C (Checkout):**
```
1. User Data Restorer runs → Data available immediately
2. Enhanced conversion tags fire with user data
```

## Setting Up Variables in GTM

### Required Data Layer Variables

After installing the template, create these **Data Layer Variables** in GTM to access restored data:

| Variable Name | Data Layer Variable Name | Description |
|---------------|--------------------------|-------------|
| `userData - Email` | `userData.email` | Original email address |
| `userData - Email Hashed` | `userData.email_hashed` | SHA-256 hashed email (GDPR compliant) |
| `userData - Phone` | `userData.phone` | Original phone number |
| `userData - Phone Hashed` | `userData.phone_hashed` | SHA-256 hashed phone (GDPR compliant) |
| `userData - First Name` | `userData.firstName` | User's first name |
| `userData - Last Name` | `userData.lastName` | User's last name |
| `userData - Country` | `userData.country` | User's country |
| `userData - City` | `userData.city` | User's city |
| `userData - Address` | `userData.address` | User's address |
| `userData - Postal Code` | `userData.postalCode` | User's postal/zip code |

### User-Provided Data Variable (Essential for Advertising)

Create a **User-Provided Data variable** for enhanced conversions using restored data:

1. **Go to Variables** → **New** → **User-Defined Variables**
2. **Choose Variable Type:** `User-Provided Data`
3. **Configure fields:**

#### For GDPR Mode (EU Clients - Recommended):
```
Variable Name: "User Data - Enhanced Conversions"

Configuration:
├── Email Address: {{userData - Email Hashed}}
├── Phone Number: {{userData - Phone Hashed}}
├── Address - First Name: {{userData - First Name}}
├── Address - Last Name: {{userData - Last Name}}
├── Address - Street: {{userData - Address}}
├── Address - City: {{userData - City}}
├── Address - Postal Code: {{userData - Postal Code}}
└── Address - Country: {{userData - Country}}
```

#### For Non-GDPR Mode:
```
Variable Name: "User Data - Enhanced Conversions"

Configuration:
├── Email Address: {{userData - Email}}
├── Phone Number: {{userData - Phone}}
├── Address - First Name: {{userData - First Name}}
├── Address - Last Name: {{userData - Last Name}}
├── Address - Street: {{userData - Address}}
├── Address - City: {{userData - City}}
├── Address - Postal Code: {{userData - Postal Code}}
└── Address - Country: {{userData - Country}}
```

### Conversion Tag Setup with Tag Sequencing

#### Google Ads Enhanced Conversions:
1. **Open your Google Ads Conversion tag**
2. **Advanced Settings** → **Tag Sequencing**
3. **Setup Tag:** Select "User Data Restorer"
4. **Enhanced Conversions** → **User-provided data from your website**
5. **Select:** `{{User Data - Enhanced Conversions}}`

#### Facebook Conversions API:
```javascript
// Configure tag sequencing first, then use:
'user_data': {
  'em': [{{userData - Email Hashed}}],      // Restored hashed email
  'ph': [{{userData - Phone Hashed}}],      // Restored hashed phone
  'fn': [{{userData - First Name}}],        // Restored first name
  'ln': [{{userData - Last Name}}],         // Restored last name
  'ct': [{{userData - City}}],              // Restored city
  'country': [{{userData - Country}}]       // Restored country
}
```

#### GA4 Enhanced Ecommerce:
```javascript
// Ensure User Data Restorer fires first via tag sequencing
gtag('event', 'purchase', {
  'transaction_id': '12345',
  'value': 25.42,
  'currency': 'USD',
  'user_data': {
    'email_address': {{userData - Email Hashed}},
    'phone_number': {{userData - Phone Hashed}},
    'address': {
      'first_name': {{userData - First Name}},
      'last_name': {{userData - Last Name}},
      'country': {{userData - Country}}
    }
  }
});
```


## Restored Data Structure

### Standard Restoration
```javascript
{
  event: 'userData.restored',
  'userData.source': 'restored_from_localStorage',
  'userData.restoredAt': '1749811721514',
  'userData.firstName': 'John',
  'userData.lastName': 'Doe',
  'userData.email': 'john.doe@example.com',
  'userData.phone': '+1234567890',
  'userData.country': 'US'
}
```

### With Hashed Data
```javascript
{
  event: 'userData.restored',
  'userData.source': 'restored_from_localStorage', 
  'userData.restoredAt': '1749811721514',
  'userData.firstName': 'John',
  'userData.lastName': 'Doe',
  'userData.email': 'john.doe@example.com',
  'userData.email_hashed': 'UQoDd1hKDBlxKKg5YZb+Q3HUp6AlXTKq2Z3B5coDxus=',
  'userData.phone_hashed': 'abc123def456...'
}
```

### GDPR Mode Restoration
```javascript
{
  event: 'userData.restored',
  'userData.source': 'restored_from_localStorage',
  'userData.restoredAt': '1749811721514', 
  'userData.firstName': 'John',
  'userData.lastName': 'Doe',
  'userData.email_hashed': 'UQoDd1hKDBlxKKg5YZb+Q3HUp6AlXTKq2Z3B5coDxus=',
  'userData.phone_hashed': 'abc123def456...'
}
```

### Consent Integration
The template respects Google Consent Mode:
- `analytics_storage`: Required for localStorage
- `ad_storage` + `ad_user_data` + `ad_personalization`: Required for full advertising functionality  
- Automatically stops processing if consent denied
- Supports granular user control over data usage

## Data Age Management

### Automatic Expiration
```javascript
// Data older than configured hours is automatically ignored
const maxAgeMs = 168 * 60 * 60 * 1000; // 7 days default
if (currentTime - dataTimestamp > maxAgeMs) {
  // Data expired - skip restoration
}
```

### Cleanup Options
- **Manual cleanup**: Enable "Clear localStorage after restore"
- **Automatic cleanup**: Old data removed when expired
- **Selective cleanup**: Only remove expired data, keep fresh data

## Integration with User Data Listener

### Complete Setup for Cross-Page Persistence

1. **Install both templates**:
   - User Data Listener (captures data)
   - User Data Restorer (restores data)

2. **Configure matching settings**:
   ```
   User Data Listener:    localStorage Key = "kg_media_user_data"
   User Data Restorer:    localStorage Key = "kg_media_user_data"
   ```

3. **Set up triggers**:
   ```
   User Data Listener:    Form submissions, clicks
   User Data Restorer:    Page View - All Pages (high priority)
   ```

### Data Flow Diagram
```
Form Submission → Listener Captures → localStorage Storage
      ↓
Page Navigation → New Page Load → Restorer Reads localStorage
      ↓
dataLayer Population → Other Tags Access User Data
```

## Events

The template pushes these events to dataLayer:

- `userData.restored`: Fired when user data is successfully restored from localStorage

### Memory Usage
- ✅ Small data footprint
- ✅ Automatic cleanup options
- ✅ Age-based expiration
- ✅ No memory leaks

## Browser Support

- Chrome/Edge: Latest 2 versions
- Firefox: Latest 2 versions
- Safari: Latest 2 versions  
- Mobile browsers: iOS Safari, Chrome for Android

## Security

- ✅ Google Consent Mode integration
- ✅ GDPR-compliant data handling
- ✅ Secure localStorage usage
- ✅ Data age validation
- ✅ No external dependencies


## License

This template is provided under the Apache License version 2.0. See LICENSE file for details.

## Support

For issues or questions:
- GitHub Issues: [https://github.com/analyticskgmedia/user-data-restorer/issues](https://github.com/analyticskgmedia/user-data-restorer/issues)
- Email: filip.aldic@kg-media.hr

## Related Templates

- **[User Data Listener](https://github.com/analyticskgmedia/user-data-listener)**: Companion template for automatic data capture
- **[GTM Consent Banner](https://github.com/analyticskgmedia/gtm-consent-banner)**: Advanced Consent Mode v2 implementation

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## Credits

Developed by [KG Media](https://kg-media.eu)

---

Made with ❤️ for the GTM community