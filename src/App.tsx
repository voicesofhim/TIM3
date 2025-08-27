import React from 'react';
import { S3ARCHUtils, DEFAULT_CONFIG } from '@s3arch/shared';

function App() {
  const [config, setConfig] = React.useState(DEFAULT_CONFIG);
  const [isValid, setIsValid] = React.useState(false);

  React.useEffect(() => {
    setIsValid(S3ARCHUtils.validateConfig(config));
  }, [config]);

  const handleConfigChange = (field: keyof S3ARCHConfig, value: string | number) => {
    setConfig(prev => ({ ...prev, [field]: value }));
  };

  return (
    <div className="tim3-app">
      <h1>TIM3 - S3ARCH Ecosystem</h1>
      
      <div className="config-section">
        <h2>Configuration</h2>
        <div className="config-item">
          <label>API Key:</label>
          <input
            type="password"
            value={config.apiKey}
            onChange={(e) => handleConfigChange('apiKey', e.target.value)}
            placeholder="Enter your API key"
          />
        </div>
        
        <div className="config-item">
          <label>Model:</label>
          <input
            type="text"
            value={config.model}
            onChange={(e) => handleConfigChange('model', e.target.value)}
          />
        </div>
        
        <div className="config-item">
          <label>Max Tokens:</label>
          <input
            type="number"
            value={config.maxTokens}
            onChange={(e) => handleConfigChange('maxTokens', parseInt(e.target.value) || 0)}
          />
        </div>
        
        <div className="validation-status">
          Status: {isValid ? '✅ Valid' : '❌ Invalid'}
        </div>
      </div>

      <div className="utils-demo">
        <h2>Shared Utilities Demo</h2>
        <p>Cost formatting: {S3ARCHUtils.formatCost(0.000123)}</p>
        <p>Token formatting: {S3ARCHUtils.formatTokens(1500)}</p>
      </div>
    </div>
  );
}

export default App;


