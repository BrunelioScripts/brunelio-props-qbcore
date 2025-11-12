console.log('[brunelio_prop] Script NUI carregado');

let visible = false;

// Aguarda o carregamento do DOM
document.addEventListener('DOMContentLoaded', () => {

    // ✅ Botão: Usar posição atual
    document.getElementById('useCurrentPos').addEventListener('click', async () => {
        console.log('🛰️ Botão "Usar Posição Atual" clicado');
        try {
            const resp = await fetch(`https://${GetParentResourceName()}/getCurrentPosition`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
            const data = await resp.json();
            console.log('📦 Dados recebidos:', JSON.stringify(data, null, 2));

            if (data && data.position) {
                document.getElementById('coordX').value = data.position.x.toFixed(2);
                document.getElementById('coordY').value = data.position.y.toFixed(2);
                document.getElementById('coordZ').value = data.position.z.toFixed(2);
                document.getElementById('heading').value = data.heading.toFixed(2);
            } else {
                console.error('❌ Dados inválidos recebidos:', data);
            }
        } catch (error) {
            console.error('⚠️ Erro ao obter posição:', error);
        }
    });

    // ✅ Botão: Limpar coordenadas
    document.getElementById('clearCoords').addEventListener('click', () => {
        console.log('🧹 Limpando coordenadas');
        clearAllFields();
    });

    // ✅ Botão: Spawnar prop
    document.getElementById('spawnProp').addEventListener('click', async () => {
        const propName = document.getElementById('propName').value.trim();
        if (!propName || propName === '') {
            console.warn('⚠️ Nenhum nome de prop especificado.');
            return;
        }

        const data = {
            propName: propName,
            coords: {
                x: parseFloat(document.getElementById('coordX').value),
                y: parseFloat(document.getElementById('coordY').value),
                z: parseFloat(document.getElementById('coordZ').value)
            },
            heading: parseFloat(document.getElementById('heading').value)
        };

        console.log('🚀 Enviando prop para spawn:', JSON.stringify(data, null, 2));

        await fetch(`https://${GetParentResourceName()}/spawnProp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data)
        });
    });

    // ✅ Botão: Remover prop próxima
    document.getElementById('removeNearestProp').addEventListener('click', async () => {
        console.log('🗑️ Tentando remover prop próxima');
        await fetch(`https://${GetParentResourceName()}/removeNearestProp`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });

    // ✅ Botão: Limpar nome da prop
    document.getElementById('clearPropName').addEventListener('click', () => {
        console.log('🧹 Limpando nome da prop');
        document.getElementById('propName').value = '';
    });

    // ✅ Botão: Fechar NUI
    document.getElementById('close').addEventListener('click', async () => {
        console.log('❎ Fechando NUI manualmente');
        await fetch(`https://${GetParentResourceName()}/closeNUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    });
});

// ✅ Recebe mensagens do client.lua (abrir/fechar UI)
window.addEventListener('message', (event) => {
    console.log('💬 Mensagem recebida:', JSON.stringify(event.data, null, 2));

    if (event.data.type === 'show') {
        document.body.style.display = 'block';
        clearAllFields();
        visible = true;
    } else if (event.data.type === 'hide') {
        document.body.style.display = 'none';
        visible = false;
    }
});

// ✅ Fecha a NUI com ESC
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape' && visible) {
        console.log('⎋ Fechando NUI via tecla ESC');
        fetch(`https://${GetParentResourceName()}/closeNUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

// 🔧 Função auxiliar para limpar campos
function clearAllFields() {
    document.getElementById('propName').value = '';
    document.getElementById('coordX').value = '';
    document.getElementById('coordY').value = '';
    document.getElementById('coordZ').value = '';
    document.getElementById('heading').value = '';
}
