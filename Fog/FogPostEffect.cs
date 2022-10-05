using UnityEngine;
using System.Collections;
[ExecuteInEditMode]
public class FogPostEffect : PostEffectsBase
{
    public Shader fogShader;
    private Material fogMaterial = null;
    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    private Camera myCamera;
    public Camera Camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    private Transform myCameraTransform;
    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = Camera.transform;
            }

            return myCameraTransform;
        }
    }

    public enum DistType
    {
        VIEWSPACE = 0,
        WORLDSPACE = 1,
    }       
    public enum AccumulateMode
    {
        LINEAR = 0,
        EXP = 1,
        EXP2 = 2
    }       
    // [Range(0.1f, 3.0f)]
    // public float fogDensity = 1.0f;//雾浓度

    public Color fogColor = Color.white;//雾颜色
    
    [Header("Noise")]
    public Texture noiseTexture;//噪声纹理
    [Range(0f, 1f)]
    public float noiseSpX = 0.5f;
    [Range(0f, 1f)]
    public float noiseSpY = 0.5f;
    [Range(0.0f, 0.1f)]
    public float worldPosScale = 0.05f;
    
    [Header("HeightFog")]
    public float heightStart = 1f;
    public float heightEnd = 0f;
    [Range(0.0f, 1.0f)]
    public float heightDensity = 0.3f;
    [Range(0.0f, 30.0f)]
    public float heightNoiseScale = 4.0f;
    
    [Header("DepthFog")]
    public float depthStart = 0f;
    public float depthEnd = 100f;
    [Range(0.0f, 0.1f)]
    public float depthDensity = 0.001f;
    [Range(0.0f, 30.0f)]
    public float depthNoiseScale = 4.0f;
    
    public DistType distType = 0;
    public AccumulateMode accumulateMode = 0;
    
    [Space(20)]
    [Range(0.0f, 1.0f)] 
    public float depthHeightRatio = 1f;
    
    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            Matrix4x4 frustumCornors = Matrix4x4.identity;
            float fov = Camera.fieldOfView;
            float near = Camera.nearClipPlane;
            float far = Camera.farClipPlane;
            float aspect = Camera.aspect;

            float fovWHalf = fov * 0.5f;

            Vector3 toRight = cameraTransform.right * near * Mathf.Tan (fovWHalf * Mathf.Deg2Rad) * aspect;
            Vector3 toTop = cameraTransform.up * near * Mathf.Tan (fovWHalf * Mathf.Deg2Rad);

            Vector3 topLeft = (cameraTransform.forward * near - toRight + toTop);
            float camScale = topLeft.magnitude * far/near;

            topLeft.Normalize();
            topLeft *= camScale;

            Vector3 topRight = (cameraTransform.forward * near + toRight + toTop);
            topRight.Normalize();
            topRight *= camScale;

            Vector3 bottomRight = (cameraTransform.forward * near + toRight - toTop);
            bottomRight.Normalize();
            bottomRight *= camScale;

            Vector3 bottomLeft = (cameraTransform.forward * near - toRight - toTop);
            bottomLeft.Normalize();
            bottomLeft *= camScale;

            frustumCornors.SetRow(0, bottomLeft);
            frustumCornors.SetRow(1, bottomRight);
            frustumCornors.SetRow(2, topRight);
            frustumCornors.SetRow(3, topLeft);

            material.SetMatrix("_Ray", frustumCornors);

            material.SetFloat("_DepthHeightRatio", depthHeightRatio);
            material.SetFloat("_DepthDensity", depthDensity);
            material.SetFloat("_HeightDensity", heightDensity);
            
            material.SetColor("_FogColor", fogColor);
            
            material.SetFloat("_HeightStart", heightStart);
            material.SetFloat("_HeightEnd", heightEnd);
            material.SetFloat("_DepthStart", depthStart);
            material.SetFloat("_DepthEnd", depthEnd);

            material.SetTexture("_NoiseTex", noiseTexture);
            material.SetFloat("_NoiseSpX", noiseSpX);
            material.SetFloat("_NoiseSpY", noiseSpY);
            material.SetFloat("_DepthNoiseScale", depthNoiseScale);
            material.SetFloat("_HeightNoiseScale", heightNoiseScale);
            
            material.SetFloat("_WorldPosScale", worldPosScale);

            switch ((int)distType)
            {
                case 0:
                    material.EnableKeyword("_DIST_TYPE_VIEWSPACE");
                    material.DisableKeyword("_DIST_TYPE_WORLDSPACE");
                    break;
                case 1:
                    material.EnableKeyword("_DIST_TYPE_WORLDSPACE");
                    material.DisableKeyword("_DIST_TYPE_VIEWSPACE");
                    break;
                default:
                    break;
            }
            
            switch ((int)accumulateMode)
            {
                case 0:
                    material.EnableKeyword("_FUNC_TYPE_LINEAR");
                    material.DisableKeyword("_FUNC_TYPE_EXP");
                    material.DisableKeyword("_FUNC_TYPE_EXP2");
                    break;
                case 1:
                    material.EnableKeyword("_FUNC_TYPE_EXP");
                    material.DisableKeyword("_FUNC_TYPE_LINEAR");
                    material.DisableKeyword("_FUNC_TYPE_EXP2");
                    break;
                case 2:
                    material.EnableKeyword("_FUNC_TYPE_EXP2");
                    material.DisableKeyword("_FUNC_TYPE_LINEAR");
                    material.DisableKeyword("_FUNC_TYPE_EXP");
                    break;
                default:
                    break;
            }

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}

