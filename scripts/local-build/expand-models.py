from pathlib import Path
import re
root=Path(__file__).resolve().parents[2]
s=(root/'LaunchNext/FolderInfo.swift').read_text()
models=[]
for name in ['TopItemData','PageEntryData']:
 start=s.index('@Model\nfinal class '+name+' {')
 end=s.index('\n}\n',start)+2
 body=s[start:end]
 props=re.findall(r'^    (?:@Attribute\(\.unique\) )?var (\w+): ([\w\[\]?]+)',body,re.M)
 assert len(props)==(8 if name=='TopItemData' else 13),props
 unique='id' if name=='TopItemData' else 'slotId'
 body=body.replace('@Model\nfinal class '+name+' {','nonisolated final class '+name+': PersistentModel {')
 for prop,typ in props:
  body=re.sub(r'^    (?:@Attribute\(\.unique\) )?var '+prop+r': '+re.escape(typ)+r'[^\n]*',f'''    var {prop}: {typ} {{
        get {{
            registrar.access(self, keyPath: \\.{prop})
            return self.getValue(forKey: \\.{prop})
        }}
        set {{
            registrar.withMutation(of: self, keyPath: \\.{prop}) {{
                self.setValue(forKey: \\.{prop}, to: newValue)
            }}
        }}
    }}'''.replace('\\','\\\\'),body,flags=re.M)
 metadata=',\n'.join(f'            .init(name: "{p}", keypath: \\{name}.{p}, defaultValue: nil, metadata: '+('Schema.Attribute(.unique)' if p==unique else 'nil')+')' for p,t in props)
 extra=f'''
    private let registrar = Observation.ObservationRegistrar()
    var persistentBackingData: any BackingData<{name}> = {name}.createBackingData()
    static var schemaMetadata: [Schema.PropertyMetadata] {{
        [
{metadata}
        ]
    }}
    init(backingData: any BackingData<{name}>) {{
        persistentBackingData = backingData
    }}
'''
 body=body[:-1]+extra+'}'
 models.append(body)
 s=s[:start]+body+s[end:]
(root/'build/local/FolderInfo.swift').write_text('import Observation\n'+s)
(root/'build/local/Models.swift').write_text('import Foundation\nimport SwiftData\nimport Observation\n'+'\n'.join(models))
