using System.Collections;
using System.Collections.Generic;
using UnityEngine;
[ExecuteInEditMode]
public class ShaderCameraSetup : MonoBehaviour
{
    private Camera mainCamera;
    void OnEnable()
    {
        mainCamera = GetComponent<Camera>();
        mainCamera.depthTextureMode = DepthTextureMode.Depth;
    }
}
