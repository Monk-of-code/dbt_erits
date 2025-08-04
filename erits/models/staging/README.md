# Staging Models - Complete Overview

## Architecture Overview

The staging layer is organized into four distinct model groups that work together to transform raw spatial data into comprehensive, analysis-ready property profiles. Each group serves a specific purpose in the data processing pipeline.

## Data Flow Architecture

```
Bronze Layer (Source Data)
           ↓
   ┌─────────────────┐
   │  Preparation    │ ← Data ingestion & validation
   │     Models      │
   └─────────────────┘
           ↓
   ┌─────────────────┐
   │ Gen UUID &      │ ← Data integration & linking
   │   Linking       │
   │    Models       │
   └─────────────────┘
           ↓
   ┌─────────────────┐
   │  Aggregate      │ ← Spatial aggregation & counting
   │   Count         │
   │   Models        │
   └─────────────────┘
           ↓
   ┌─────────────────┐
   │    Interest     │ ← Business intelligence & integration
   │    Models       │
   └─────────────────┘
           ↓
   Gold Layer (Analysis & Reporting)
```

## Model Groups

### 1. Preparation Models
**Purpose**: Data ingestion and validation layer
- Filters source data to Langata subcounty boundaries
- Validates and repairs geometries
- Ensures coordinate reference system compliance (SRID 4326)
- Prepares clean, standardized data for downstream processing

**Key Functions**:
- Spatial filtering to administrative boundaries
- Geometry validation and repair
- SRID standardization
- Data quality assurance

### 2. Gen UUID and Linking Models
**Purpose**: Data integration and linking layer
- Generates unique identifiers for cadastral parcels
- Establishes spatial relationships between different data layers
- Links utility data (power, water) to cadastral parcels
- Links building and permit data to cadastral parcels
- Links address data to cadastral parcels

**Key Functions**:
- UUID generation and management
- Spatial intersection linking
- Cross-dataset relationship establishment
- Data integration foundation

### 3. Aggregate Count Models
**Purpose**: Spatial aggregation and counting layer
- Counts features within each cadastral parcel boundary
- Creates summary statistics for property analysis
- Enables property-level insights and comparisons
- Provides foundation for business intelligence and reporting

**Key Functions**:
- Spatial aggregation operations
- Feature counting and density calculation
- Property profiling and classification
- Multi-dimensional analysis preparation

### 4. Interest Models
**Purpose**: Business intelligence and interest integration layer
- Integrates land rate data with spatial property information
- Links trade license information to properties
- Creates comprehensive property profiles for business analysis
- Enables revenue collection and compliance monitoring

**Key Functions**:
- Financial data integration
- Regulatory compliance tracking
- Business intelligence foundation
- Revenue collection support

## Data Quality Framework

### Data Integrity
- UUID uniqueness across all models
- Referential integrity maintenance
- Spatial relationship validation
- Data completeness assurance

## Performance Optimization

### Spatial Indexing
All models create spatial indexes for performance:
```sql
"CREATE INDEX IF NOT EXISTS idx_model_name_geom ON {{ this }} USING GIST (geom)"
```

### UUID Indexing
All models create UUID indexes for fast joins:
```sql
"CREATE INDEX IF NOT EXISTS idx_model_name_uuid ON {{ this }} (uuid)"
```

### Query Optimization
- Efficient spatial operations
- Selective attribute carrying to reduce data volume
- Optimized intersection operations
- Efficient aggregation strategies

## Testing Strategy

### Comprehensive Test Coverage
Each model group has specific test requirements:

**Preparation Models**:
- Non-null geometries
- Non-empty geometries

**Gen UUID and Linking Models**:
- UUID uniqueness
- Spatial relationship integrity

**Aggregate Count Models**:
- UUID uniqueness
- Count accuracy
- Data completeness

**Interest Models**:
- UUID uniqueness
- Data completeness
- Financial data accuracy

### Test Execution
```bash
# Test all staging models
dbt test --models staging

# Test specific model groups
dbt test --models staging.preparation
dbt test --models staging.gen_uuid_and_linking
dbt test --models staging.aggregate_count
dbt test --models staging.interest

# Test specific test types
dbt test --select test_type:unique_uuid
## Maintenance and Operations

### Regular Monitoring Tasks
1. **Data Quality Monitoring**: Check for geometry validation failures
2. **Performance Monitoring**: Track query performance and optimize
3. **Dependency Monitoring**: Ensure all model dependencies are current
4. **Business Rule Validation**: Verify business logic and rules

### Troubleshooting Guide
1. **Geometry Errors**: Check source data for invalid geometries
2. **SRID Issues**: Verify source data coordinate reference system
3. **Missing Data**: Confirm source tables have data for Langata area
4. **Performance Issues**: Review spatial index usage and query plans
5. **Linking Problems**: Check spatial intersection accuracy
6. **Aggregation Issues**: Verify counting logic and data completeness

### Best Practices
1. **Always validate geometries** before spatial operations
2. **Use consistent SRID** (4326) across all spatial data
3. **Create spatial indexes** for performance optimization
4. **Filter early** to reduce downstream processing load
5. **Document data lineage** and dependencies clearly
6. **Monitor data quality** and accuracy regularly
7. **Optimize performance** through proper indexing and query design
8. **Maintain referential integrity** across all model relationships

## Integration Points

### Input Sources
- `bronze_source.address`
- `bronze_source.buildings`
- `bronze_source.building_permits`
- `bronze_source.cadastral_parcel`
- `bronze_source.power_customers`
- `bronze_source.water_meters`
- `bronze_source.au_subcounty_unit`
- `bronze_source.bd_land_rate_data`
- `bronze_source.trade_license`
