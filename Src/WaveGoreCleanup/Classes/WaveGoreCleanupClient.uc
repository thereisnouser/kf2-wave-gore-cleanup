// Wave Gore Cleanup 0.1.0
// Runs on each client. Gore is stored locally, not on the dedicated server.
class WaveGoreCleanupClient extends Info;

var transient bool bCleanedActiveWave;
var transient int LastCleanedWave;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    // A dedicated server has no rendered blood or ragdoll pool to clean.
    if (WorldInfo.NetMode != NM_DedicatedServer)
    {
        SetTimer(0.25, true, 'CheckWaveStart');
    }
}

simulated function CheckWaveStart()
{
    local KFGameReplicationInfo KFGRI;

    if (WorldInfo.NetMode == NM_DedicatedServer)
    {
        return;
    }

    KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
    if (KFGRI == None)
    {
        return;
    }

    if (!KFGRI.bWaveStarted)
    {
        bCleanedActiveWave = false;
        return;
    }

    // Execute exactly once per new wave on each connected client.
    if (bCleanedActiveWave && LastCleanedWave == int(KFGRI.WaveNum))
    {
        return;
    }

    if (CleanupLocalGore())
    {
        LastCleanedWave = int(KFGRI.WaveNum);
        bCleanedActiveWave = true;
    }
}

simulated function bool CleanupLocalGore()
{
    local KFGoreManager Gore;
    local KFGiblet Gib;
    local int i;

    Gore = KFGoreManager(WorldInfo.MyGoreEffectManager);
    if (Gore == None)
    {
        // Retry on next timer tick if the client is still loading the map.
        return false;
    }

    // Uses the same engine APIs as KFCheatManager's ClearSplatters / ClearCorpses,
    // but does NOT enable cheat mode or call any cheat exec command.
    Gore.ClearPersistentBloodSplats();

    // Temporary splatter/pool decals have separate local DecalManager pools.
    // Their Reset() implementation clears the active decal list, when exposed.
    if (Gore.BloodSplatterDecalManager != None)
    {
        Gore.BloodSplatterDecalManager.Reset();
    }
    if (Gore.BloodPoolDecalManager != None)
    {
        Gore.BloodPoolDecalManager.Reset();
    }

    // Never iterate all pawns: only remove objects in the dead-corpse pool.
    for (i = Gore.CorpsePool.Length - 1; i >= 0; --i)
    {
        Gore.RemoveAndDeleteCorpse(i);
    }

    // Only cosmetic giblets: never touch dropped weapons or pickup classes.
    foreach WorldInfo.AllActors(class'KFGiblet', Gib)
    {
        Gib.Destroy();
    }

    `log("[Wave Gore Cleanup] Local gore cleanup completed");
    return true;
}

defaultproperties
{
    RemoteRole=ROLE_SimulatedProxy
    bOnlyRelevantToOwner=true
    bAlwaysRelevant=false
    bReplicateMovement=false
    bHidden=true
    bCollideActors=false
    bBlockActors=false
    bBlockPlayers=false
}
