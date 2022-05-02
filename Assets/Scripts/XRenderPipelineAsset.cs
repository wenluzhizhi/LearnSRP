using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "SRPLearn/XRendererPipelineAsset")]
public class XRenderPipelineAsset : RenderPipelineAsset
{

    [SerializeField]
    private bool _srpBatcher = true;

    public bool enableSrpBatcher
    {
        get
        {
            return _srpBatcher;
        }
    }



    protected override RenderPipeline CreatePipeline() {
       return new XRenderPipeline(this);
   }
}

public class XRenderPipeline: RenderPipeline {


    private CommandBuffer _command = new CommandBuffer();

    public XRenderPipeline(XRenderPipelineAsset setting)
    {
        GraphicsSettings.useScriptableRenderPipelineBatching = setting.enableSrpBatcher;
        _command.name = "RenderCamera";
    }

    private void ClearCameraTarget(ScriptableRenderContext context, Camera camera)
    {
        _command.Clear();
        _command.SetRenderTarget(BuiltinRenderTextureType.CameraTarget, BuiltinRenderTextureType.CameraTarget);
        _command.ClearRenderTarget(true, true, camera.backgroundColor);
        context.ExecuteCommandBuffer(_command);
    }

    protected override void Render(ScriptableRenderContext context, Camera[] camears) {


        CommandBuffer cmd = new CommandBuffer();
        cmd.ClearRenderTarget(true, true, Color.black);
        context.ExecuteCommandBuffer(cmd);
        cmd.Release();



         foreach(var camera in camears) {
             RenderPerCamera(context, camera);

            if (camera.clearFlags == CameraClearFlags.Skybox && RenderSettings.skybox != null)
            {
                context.DrawSkybox(camera);
            }
        }
         context.Submit();
    }

    private ShaderTagId _shaderTag = new ShaderTagId("XForwardBase");

    private LightConfigurator _lightConfigurator = new LightConfigurator();
    private ShadowCasterPass _shadowCastPass = new ShadowCasterPass();


    private void RenderPerCamera(ScriptableRenderContext context, Camera camera) {
        context.SetupCameraProperties(camera);
        //对场景进行裁剪
        camera.TryGetCullingParameters(out var cullingParams);
        CullingResults cullingResults = context.Cull(ref cullingParams);

        LightData lightData = _lightConfigurator.SetupShaderLightingParams(context, ref cullingResults);

        _shadowCastPass.Execute(context, camera, ref cullingResults, ref lightData);

        context.SetupCameraProperties(camera);

        ClearCameraTarget(context, camera);

        //相关参数，用来计算物体渲染时的排序
       
        var drawSetting = CreateDrawSettings(camera);
        //相关参数，用来过滤需要渲染的物体
        var filterSetting = new FilteringSettings(RenderQueueRange.all);
        //绘制物体
        context.DrawRenderers(cullingResults, ref drawSetting, ref filterSetting);


    }


    private DrawingSettings CreateDrawSettings(Camera camera)
    {
        var sortingSetting = new SortingSettings(camera);
        var drawSetting = new DrawingSettings(_shaderTag, sortingSetting);
        return drawSetting;
    }
}
