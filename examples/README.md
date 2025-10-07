# Network Templates Examples

This directory contains example configurations and usage patterns for network device templates.

## Template Usage Examples

### 1. Basic Router Configuration
See `router-basic-example.yaml` for a minimal router setup with:
- Basic interface configuration
- Simple routing (static + OSPF)
- Security access lists
- SNMP monitoring

### 2. Advanced Switch Configuration  
See `switch-advanced-example.yaml` for comprehensive switch setup with:
- Multiple VLANs and port configurations
- Spanning Tree Protocol optimization
- Advanced security features (port security, DHCP snooping, DAI)
- Management interface configuration

### 3. Multi-Environment Templates
Templates can be customized for different environments:
- **Production**: Full security, comprehensive monitoring
- **Staging**: Relaxed security, debug logging
- **Development**: Minimal config, easy access

## Template Validation

All templates must validate against the JSON schema in `../schemas/device-template-schema.json`.

### Validation Command
```bash
# Install ajv-cli for JSON schema validation
npm install -g ajv-cli

# Validate a template
ajv validate -s ../schemas/device-template-schema.json -d ../templates/router-production-v1.yaml
```

## Environment-Specific Configurations

### Production Environment
- Enhanced security settings
- Comprehensive logging 
- SNMP monitoring enabled
- Backup configurations

### Staging Environment  
- Debug logging enabled
- Relaxed access controls
- Test-friendly settings
- Rapid deployment configs

### Development Environment
- Minimal security
- Console access enabled
- Quick iteration support
- Local development IPs

## Best Practices

1. **Naming Convention**: `{device-type}-{environment}-{version}.yaml`
2. **Version Control**: Increment version for any breaking changes
3. **Validation**: Always validate against schema before committing
4. **Documentation**: Include detailed descriptions for complex configurations
5. **Testing**: Test templates in staging before production deployment
