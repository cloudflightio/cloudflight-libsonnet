(import 'cloudflight-libsonnet/databases/mssql.libsonnet')
+ {
  _config+: {
    mssql+: {
      rootPassword: 'Upper/LowercaseAndANumb3r',
      acceptEula: true,
    },
  },
}
