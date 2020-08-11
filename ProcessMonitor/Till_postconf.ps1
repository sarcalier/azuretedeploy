#installing some missing component
Enable-WindowsOptionalFeature -Online -FeatureName WAS-NetFxEnvironment -All


#Installing the Sql Express
choco install sql-server-express --version=14.1801.3958.1 -y