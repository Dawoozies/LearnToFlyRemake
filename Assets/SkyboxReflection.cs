using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Rendering;

public class SkyboxReflection : MonoBehaviour
{
    private RenderTexture reflectionTexture;
    private ReflectionProbe probe;
    private MeshRenderer meshRenderer;
    private Material instancedMaterial;
    void Start()
    {
        probe = GetComponent<ReflectionProbe>();
        int probeResolution = probe.resolution;
        reflectionTexture = new RenderTexture(probeResolution,probeResolution, GraphicsFormat.R8G8B8A8_SRGB, GraphicsFormat.D32_SFloat_S8_UInt);
        reflectionTexture.dimension = TextureDimension.Cube;
        reflectionTexture.Create();
        meshRenderer = GetComponent<MeshRenderer>();
        instancedMaterial = new Material(meshRenderer.material);
        instancedMaterial.SetTexture("_ReflectionMap", reflectionTexture);
        meshRenderer.material = instancedMaterial;
        probe.realtimeTexture = reflectionTexture;
    }
    void Update()
    {
        //probe.RenderProbe(reflectionTexture);
    }
}
